import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'
    show HookWidget, useAnimationController, useEffect, useState, useTextEditingController;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart' show Gap;
import 'package:hooks_riverpod/hooks_riverpod.dart' show HookConsumerWidget, WidgetRef;
import 'package:whitenoise/hooks/use_image_picker.dart';
import 'package:whitenoise/hooks/use_signup.dart' show useSignup;
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/auth_provider.dart' show authProvider;
import 'package:whitenoise/routes.dart' show Routes;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_avatar.dart' show WnAvatar, WnAvatarSize;
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_input.dart' show WnInput;
import 'package:whitenoise/widgets/wn_input_text_area.dart' show WnInputTextArea;
import 'package:whitenoise/widgets/wn_onboarding_carousel.dart' show WnOnboardingCarousel;
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

class SignupScreen extends HookConsumerWidget {
  const SignupScreen({super.key});

  static const _animationDuration = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final displayNameController = useTextEditingController();
    final bioController = useTextEditingController();
    final (:state, :submit, :onImageSelected, :clearErrors) = useSignup(
      () => ref.read(authProvider.notifier).signup(),
    );
    final (:pickImage, error: imagePickerError, clearError: clearImagePickerError) = useImagePicker(
      onImageSelected: onImageSelected,
    );
    final noticeMessage = useState<String?>(null);
    final showCarousel = useState(false);

    final carouselAnimationController = useAnimationController(
      duration: _animationDuration,
    );

    void showNotice(String message) {
      noticeMessage.value = message;
    }

    void dismissNotice() {
      noticeMessage.value = null;
    }

    void openCarousel() {
      showCarousel.value = true;
      carouselAnimationController.forward();
    }

    void closeCarousel() {
      carouselAnimationController.reverse().then((_) {
        showCarousel.value = false;
      });
    }

    useEffect(() {
      if (imagePickerError != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showNotice(context.l10n.imagePickerError);
          }
        });
        clearImagePickerError();
      }
      return null;
    }, [imagePickerError]);

    Future<void> onSubmit() async {
      final success = await submit(
        displayName: displayNameController.text.trim(),
        bio: bioController.text.trim(),
      );
      if (success && context.mounted) {
        Routes.goToChatList(context);
      }
    }

    final slideAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, 1),
        ).animate(
          CurvedAnimation(
            parent: carouselAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    final fadeAnimation = CurvedAnimation(
      parent: carouselAnimationController,
      curve: Curves.easeInOut,
    );

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!showCarousel.value)
            Positioned.fill(
              child: GestureDetector(
                key: const Key('signup_background'),
                onTap: () => Routes.goBack(context),
                behavior: HitTestBehavior.translucent,
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _LearnMoreButton(
                key: const Key('learn_more_button'),
                onTap: openCarousel,
                visible: !showCarousel.value,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 70.h),
                Expanded(
                  child: SlideTransition(
                    position: slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: WnSlate(
                            header: WnSlateNavigationHeader(
                              title: context.l10n.setupProfile,
                              type: WnSlateNavigationType.back,
                              onNavigate: () => Routes.goBack(context),
                            ),
                            systemNotice: noticeMessage.value != null
                                ? WnSystemNotice(
                                    key: ValueKey(noticeMessage.value),
                                    title: noticeMessage.value!,
                                    type: WnSystemNoticeType.error,
                                    onDismiss: dismissNotice,
                                  )
                                : null,
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                                child: Column(
                                  spacing: 16.h,
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: ValueListenableBuilder(
                                        valueListenable: displayNameController,
                                        builder: (context, value, child) {
                                          return WnAvatar(
                                            pictureUrl: state.selectedImagePath,
                                            displayName: value.text,
                                            size: WnAvatarSize.large,
                                            onEditTap: state.isLoading ? null : pickImage,
                                          );
                                        },
                                      ),
                                    ),
                                    WnInput(
                                      label: context.l10n.chooseName,
                                      placeholder: context.l10n.enterYourName,
                                      controller: displayNameController,
                                      errorText: state.displayNameError,
                                      onChanged: (_) => clearErrors(),
                                    ),
                                    WnInputTextArea(
                                      label: context.l10n.introduceYourself,
                                      placeholder: context.l10n.writeSomethingAboutYourself,
                                      controller: bioController,
                                      textInputAction: TextInputAction.done,
                                    ),
                                    Column(
                                      spacing: 8.h,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        WnButton(
                                          text: context.l10n.cancel,
                                          type: WnButtonType.outline,
                                          onPressed: () => Routes.goBack(context),
                                          disabled: state.isLoading,
                                        ),
                                        WnButton(
                                          text: context.l10n.signUp,
                                          onPressed: onSubmit,
                                          loading: state.isLoading,
                                          disabled: state.isLoading,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Gap(10.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showCarousel.value)
            Positioned.fill(
              child: FadeTransition(
                opacity: fadeAnimation,
                child: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 80.h),
                          child: const WnOnboardingCarousel(
                            key: Key('signup_onboarding_carousel'),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: _BackToSignUpButton(
                          key: const Key('back_to_signup_button'),
                          onTap: closeCarousel,
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LearnMoreButton extends HookWidget {
  const _LearnMoreButton({
    super.key,
    required this.onTap,
    required this.visible,
  });

  final VoidCallback onTap;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final l10n = context.l10n;

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !visible,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_upward,
                  key: const Key('learn_more_arrow'),
                  size: 20.sp,
                  color: colors.backgroundContentPrimary,
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.learnMore,
                  style: typography.medium14.copyWith(
                    color: colors.backgroundContentPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackToSignUpButton extends StatelessWidget {
  const _BackToSignUpButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final l10n = context.l10n;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: colors.borderTertiary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.backToSignUp,
              style: typography.medium14.copyWith(
                color: colors.backgroundContentPrimary,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_downward,
              key: const Key('back_to_signup_arrow'),
              size: 16.sp,
              color: colors.backgroundContentPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
