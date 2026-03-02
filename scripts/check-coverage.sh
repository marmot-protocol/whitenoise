#!/bin/bash
# Check Flutter test coverage
#
# Usage:
#   ./scripts/check-coverage.sh                    # Just print coverage %
#   ./scripts/check-coverage.sh --min 80           # Fail if below 80%
#
# Excludes auto-generated files:
# - lib/src/rust/ (flutter_rust_bridge)
# - lib/l10n/generated/ (flutter_localizations)
# - *.freezed.dart (freezed)
# - *.g.dart (json_serializable, etc.)

set -euo pipefail

# Default values
LCOV_FILE="coverage/lcov.info"
MIN_COVERAGE=""

print_error() {
	printf '%b%s%b\n' "\e[31;1m" "$1" "\e[0m" >&2
}

print_success() {
	printf '%b%s%b\n' "\e[32;1m" "$1" "\e[0m" >&2
}

print_warning() {
	printf '%b%s%b\n' "\e[33;1m" "$1" "\e[0m" >&2
}

raise_error() {
	print_error "$1"
	exit 1
}

parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		--min)
			MIN_COVERAGE="$2"
			shift 2
			;;
		*)
			LCOV_FILE="$1"
			shift
			;;
		esac
	done
}

check_lcov_file_presence() {
	if [ ! -f "$LCOV_FILE" ]; then
		raise_error "Error: $LCOV_FILE not found. Run 'flutter test --coverage' first."
	fi
}

is_generated_file() {
	local file="$1"
	if [[ "$file" == *".freezed.dart" ]] ||
		[[ "$file" == *".g.dart" ]] ||
		[[ "$file" == lib/src/rust/* ]] ||
		[[ "$file" == lib/l10n/generated/* ]]; then
		return 0
	fi
	return 1
}

is_coverage_ignored() {
	local file="$1"
	grep -q '// coverage:ignore-file' "$file"
}

count_lines() {
	local file="$1"
	wc -l <"$file" | tr -d ' '
}

get_covered_files() {
	grep "^SF:" "$LCOV_FILE" | sed 's/^SF://' | sort -u
}

generate_zero_coverage_record() {
	local file="$1"
	local line_count="$2"

	echo "SF:$file"
	for ((i = 1; i <= line_count; i++)); do
		echo "DA:$i,0"
	done
	echo "LF:$line_count"
	echo "LH:0"
	echo "end_of_record"
}

print_missing_files_warning() {
	local missing_count="$1"
	shift
	local missing_files=("$@")

	if [ "$missing_count" -gt 0 ]; then
		print_warning "⚠️  Found $missing_count file(s) with no test coverage:"
		for file in "${missing_files[@]}"; do
			print_warning "   - $file"
		done
	fi
}

inject_missing_files() {
	local missing_count=0
	local missing_files=()
	local covered_files
	covered_files=$(get_covered_files)

	while IFS= read -r -d '' dart_file; do
		dart_file="${dart_file#./}"

		if is_generated_file "$dart_file"; then
			continue
		fi

		if is_coverage_ignored "$dart_file"; then
			continue
		fi

		if echo "$covered_files" | grep -qx "$dart_file"; then
			continue
		fi

		local line_count
		line_count=$(count_lines "$dart_file")

		if [ "$line_count" -gt 0 ]; then
			generate_zero_coverage_record "$dart_file" "$line_count" >>"$LCOV_FILE"
			missing_files+=("$dart_file")
			missing_count=$((missing_count + 1))
		fi
	done < <(find lib -name "*.dart" -type f -print0 2>/dev/null)

	if [ "$missing_count" -gt 0 ]; then
		print_missing_files_warning "$missing_count" "${missing_files[@]}"
	fi
}

filter_generated_files() {
	awk '
    BEGIN { skip = 0 }
    /^SF:/ {
        file = substr($0, 4)
        skip = 0
        if (match(file, /lib\/src\/rust\//) ||
            match(file, /lib\/l10n\/generated\//) ||
            match(file, /\.freezed\.dart$/) ||
            match(file, /\.g\.dart$/)) {
            skip = 1
        }
    }
    /^end_of_record$/ {
        if (!skip) print
        skip = 0
        next
    }
    { if (!skip) print }
    ' "$LCOV_FILE" >"${LCOV_FILE}.tmp"
	mv "${LCOV_FILE}.tmp" "$LCOV_FILE"
}

calculate_coverage() {
	awk '
    BEGIN {
        total_lines = 0
        covered_lines = 0
        skip = 0
    }
    /^SF:/ {
        file = substr($0, 4)
        skip = 0
        if (match(file, /lib\/src\/rust\//) ||
            match(file, /lib\/l10n\/generated\//) ||
            match(file, /\.freezed\.dart$/) ||
            match(file, /\.g\.dart$/)) {
            skip = 1
        }
    }
    /^LF:/ {
        if (!skip) total_lines += substr($0, 4)
    }
    /^LH:/ {
        if (!skip) covered_lines += substr($0, 4)
    }
    END {
        if (total_lines > 0) {
            printf "%.2f\n", (covered_lines / total_lines) * 100
        } else {
            print "0.00"
        }
    }
    ' "$LCOV_FILE"
}

check_coverage_threshold() {
	local coverage="$1"
	local min_coverage="$2"

	if (($(awk "BEGIN {print ($coverage >= $min_coverage)}"))); then
		return 0
	fi
	return 1
}

print_coverage_result() {
	local coverage="$1"
	local min_coverage="$2"

	if check_coverage_threshold "$coverage" "$min_coverage"; then
		print_success "✅ Coverage: ${coverage}%"
		exit 0
	else
		print_error "❌ Coverage: ${coverage}% (below minimum ${min_coverage}%)"
		exit 1
	fi
}

main() {
	parse_arguments "$@"
	check_lcov_file_presence
	inject_missing_files
	filter_generated_files

	local coverage
	coverage=$(calculate_coverage)

	if [ -z "$MIN_COVERAGE" ]; then
		echo "$coverage"
		exit 0
	fi

	print_coverage_result "$coverage" "$MIN_COVERAGE"
}

main "$@"
