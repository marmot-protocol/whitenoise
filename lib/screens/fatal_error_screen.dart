import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:whitenoise/utils/app_flavor.dart';

class FatalErrorScreen extends StatelessWidget {
  const FatalErrorScreen({super.key, required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/svgs/whitenoise.svg',
                  width: 80,
                  height: 62,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
                const Spacer(),
                SvgPicture.asset(
                  'assets/svgs/warning_filled.svg',
                  key: const Key('fatal_error_icon'),
                  width: 32,
                  height: 32,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
                const SizedBox(height: 16),
                const Text(
                  isStaging ? 'Bindings out of date' : 'Something went wrong',
                  key: Key('fatal_error_title'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  isStaging
                      ? 'The Flutter-Rust bridge bindings are out of sync with the compiled Rust library.\n\nRun `just generate` and restart the app.'
                      : 'An unexpected error occurred during startup. Please reinstall the app or contact support.',
                  key: Key('fatal_error_message'),
                  style: TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 15,
                    height: 1.5,
                    fontFamily: 'Manrope',
                  ),
                ),
                if (isStaging) ...[
                  const SizedBox(height: 24),
                  _ErrorDetailBox(error: error, stackTrace: stackTrace),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorDetailBox extends StatelessWidget {
  const _ErrorDetailBox({required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  String get _errorText {
    final buf = StringBuffer(error.toString());
    if (stackTrace != null) {
      buf.writeln();
      buf.writeln();
      buf.write(stackTrace.toString());
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('fatal_error_detail_box'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          constraints: const BoxConstraints(maxHeight: 160),
          child: SingleChildScrollView(
            child: Text(
              _errorText,
              style: const TextStyle(
                color: Color(0xFFCC4444),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const Key('fatal_error_copy_button'),
          onPressed: () => Clipboard.setData(ClipboardData(text: _errorText)),
          icon: const Icon(Icons.copy, size: 16, color: Color(0xFFAAAAAA)),
          label: const Text(
            'Copy error',
            style: TextStyle(color: Color(0xFFAAAAAA), fontFamily: 'Manrope'),
          ),
        ),
      ],
    );
  }
}
