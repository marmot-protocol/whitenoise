import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:whitenoise/utils/app_flavor.dart';

class FatalErrorScreen extends StatelessWidget {
  const FatalErrorScreen({
    super.key,
    required this.error,
    this.stackTrace,
    this.showDiagnostics = isStaging,
  });

  final Object error;
  final StackTrace? stackTrace;
  final bool showDiagnostics;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(420, 912),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/svgs/whitenoise.svg',
                      width: 80.w,
                      height: 62.h,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    const Spacer(),
                    SvgPicture.asset(
                      'assets/svgs/warning_filled.svg',
                      key: const Key('fatal_error_icon'),
                      width: 32.w,
                      height: 32.h,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      showDiagnostics ? 'Bindings out of date' : 'Something went wrong',
                      key: const Key('fatal_error_title'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      showDiagnostics
                          ? 'The Flutter-Rust bridge bindings are out of sync with the compiled Rust library.\n\nRun `just generate` and restart the app.'
                          : 'An unexpected error occurred during startup. Please reinstall the app or contact support.',
                      key: const Key('fatal_error_message'),
                      style: TextStyle(
                        color: const Color(0xFFAAAAAA),
                        fontSize: 15.sp,
                        height: 1.5,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    if (showDiagnostics) ...[
                      SizedBox(height: 24.h),
                      _ErrorDetailBox(error: error, stackTrace: stackTrace),
                    ],
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          constraints: BoxConstraints(maxHeight: 160.h),
          child: SingleChildScrollView(
            child: Text(
              _errorText,
              style: TextStyle(
                color: const Color(0xFFCC4444),
                fontSize: 11.sp,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        TextButton.icon(
          key: const Key('fatal_error_copy_button'),
          onPressed: () => Clipboard.setData(ClipboardData(text: _errorText)),
          icon: Icon(Icons.copy, size: 16.r, color: const Color(0xFFAAAAAA)),
          label: Text(
            'Copy error',
            style: TextStyle(
              color: const Color(0xFFAAAAAA),
              fontSize: 12.sp,
              fontFamily: 'Manrope',
            ),
          ),
        ),
      ],
    );
  }
}
