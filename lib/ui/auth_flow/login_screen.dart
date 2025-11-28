import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/ui/auth_flow/auth_header.dart';
import 'package:whitenoise/ui/auth_flow/controllers/login_controller.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/status_bar_utils.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with WidgetsBindingObserver {
  final TextEditingController _keyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _wasKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _keyController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _handleKeyboardVisibility();
  }

  void _handleKeyboardVisibility() {
    final keyboardVisible = View.of(context).viewInsets.bottom > 0;

    // Check if keyboard just became visible and text field has focus
    if (keyboardVisible && !_wasKeyboardVisible && _focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    _wasKeyboardVisible = keyboardVisible;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    final controller = ref.watch(loginControllerProvider(context));

    return StatusBarUtils.wrapWithAdaptiveIcons(
      context: context,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: context.colors.neutral,
        appBar: AuthAppBar(title: 'auth.loginToWhiteNoise'.tr()),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24).w,
            controller: _scrollController,
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height -
                  (MediaQuery.of(context).padding.top +
                      MediaQuery.of(context).padding.bottom +
                      56.h),
              child: Column(
                children: [
                  const Spacer(),
                  Center(
                    child: WnImage(
                      AssetsPaths.login,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: 345.h,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'auth.enterYourPrivateKey'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                      Gap(6.h),
                      Row(
                        children: [
                          Expanded(
                            child: WnTextFormField(
                              hintText: 'nsec...',
                              type: FieldType.password,
                              controller: _keyController,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                suffixIcon: GestureDetector(
                                  onTap: () async {
                                    final scannedCode = await controller.scanQRCode();
                                    if (scannedCode != null && scannedCode.isNotEmpty) {
                                      _keyController.text = scannedCode;
                                      setState(() {});
                                    }
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(12.w),
                                    child: WnImage(
                                      AssetsPaths.icScan,
                                      size: 16.w,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Gap(4.w),
                          // Used .h for bothe to make it square and also go along with the 56.h
                          // calculation I made in WnTextFormField's vertical: 19.h.
                          // IntrinsicHeight avoided here since it's been used once in this page already.
                          // PS this has been tested on different screen sizes and it works fine.
                          Container(
                            height: 56.h,
                            width: 56.h,
                            decoration: BoxDecoration(
                              color: context.colors.avatarSurface,
                            ),
                            child: WnIconButton(
                              iconPath: AssetsPaths.icPaste,
                              onTap: () async {
                                await controller.pasteFromClipboard((text) {
                                  _keyController.text = text;
                                });
                              },
                              padding: 20.w,
                              size: 56.h,
                            ),
                          ),
                        ],
                      ),
                      Gap(8.h),
                      Consumer(
                        builder: (context, ref, child) {
                          final authState = ref.watch(authProvider);
                          return WnFilledButton(
                            loading: authState.isLoading,
                            onPressed:
                                _keyController.text.isEmpty
                                    ? null
                                    : () =>
                                        controller.onContinuePressed(_keyController.text.trim()),
                            label: 'auth.login'.tr(),
                          );
                        },
                      ),
                      Gap(16.h),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
