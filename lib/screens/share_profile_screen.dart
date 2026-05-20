import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/providers/deep_link_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/deep_links.dart';
import 'package:whitenoise/utils/formatting.dart';
import 'package:whitenoise/utils/metadata.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_copy_card.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart' show WnSystemNotice;

class ShareProfileScreen extends HookConsumerWidget {
  const ShareProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final pubkey = ref.watch(accountPubkeyProvider);
    final metadataSnapshot = useUserMetadata(context, pubkey);
    final npub = npubFromHex(pubkey);
    final deepLinkSchemeState = ref.watch(deepLinkSchemeProvider);
    final profileDeepLink = npub != null && deepLinkSchemeState.hasValue
        ? DeepLinks.userUri(npub, scheme: deepLinkSchemeState.value!)
        : null;
    final (:noticeMessage, :noticeType, :showSuccessNotice, :showErrorNotice, :dismissNotice) =
        useSystemNotice();

    final metadata = metadataSnapshot.data;
    final displayName = presentName(metadata);

    final qrRepaintKey = useMemoized(GlobalKey.new);
    final isHolding = useState(false);
    final dotCount = useState(0);
    final qrColorAnim = useAnimationController(
      duration: const Duration(milliseconds: 150),
    );
    final qrColor = ColorTween(
      begin: colors.backgroundContentPrimary,
      end: Colors.grey,
    ).animate(CurvedAnimation(parent: qrColorAnim, curve: Curves.easeIn));

    final isMounted = useRef(true);
    final isCapturing = useRef(false);
    useEffect(
      () =>
          () => isMounted.value = false,
      const [],
    );

    Future<void> captureAndShareQr() async {
      if (isCapturing.value) return;
      isCapturing.value = true;
      final boundary = qrRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        isCapturing.value = false;
        return;
      }
      final errorMessage = context.l10n.shareQrCodeError;
      // Capture synchronously before any animation frame can render, so the
      // image is always the full-color QR regardless of animation state.
      dotCount.value = 1;
      qrColorAnim.forward();
      final captureFuture = boundary
          .toImageSync(pixelRatio: 3)
          .toByteData(format: ui.ImageByteFormat.png);
      // onLongPressStart fires at 500ms total; dots step every 500ms after that
      await Future.delayed(const Duration(milliseconds: 500));
      if (!isMounted.value || !isHolding.value) {
        isCapturing.value = false;
        return;
      }
      dotCount.value = 2;
      await Future.delayed(const Duration(milliseconds: 500));
      if (!isMounted.value || !isHolding.value) {
        isCapturing.value = false;
        return;
      }
      dotCount.value = 3;
      try {
        final byteData = await captureFuture;
        if (!isMounted.value || byteData == null || !isHolding.value) {
          isCapturing.value = false;
          return;
        }
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                byteData.buffer.asUint8List(),
                name: 'qr_code.png',
                mimeType: 'image/png',
              ),
            ],
          ),
        );
      } catch (e) {
        if (isMounted.value) {
          dotCount.value = 0;
          qrColorAnim.reverse();
          showErrorNotice(errorMessage);
        }
      } finally {
        isCapturing.value = false;
      }
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          header: WnSlateNavigationHeader(
            title: context.l10n.shareProfileTitle,
            onNavigate: () => Routes.goBack(context),
          ),
          systemNotice: noticeMessage != null
              ? WnSystemNotice(
                  key: ValueKey(noticeMessage),
                  title: noticeMessage,
                  type: noticeType,
                  onDismiss: dismissNotice,
                )
              : null,
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  WnAvatar(
                    pictureUrl: metadata?.picture,
                    displayName: displayName,
                    size: WnAvatarSize.large,
                    color: AvatarColor.fromPubkey(pubkey),
                  ),
                  Gap(8.h),
                  if (displayName != null)
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: typography.semiBold16.copyWith(
                        color: colors.backgroundContentPrimary,
                      ),
                    ),
                  Gap(16.h),
                  if (npub != null) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: WnCopyCard(
                        textToDisplay: formatPublicKey(npub),
                        textToCopy: npub,
                        onCopySuccess: () => showSuccessNotice(context.l10n.publicKeyCopied),
                        onCopyError: () => showErrorNotice(
                          context.l10n.publicKeyCopyError,
                        ),
                        snapToWords: true,
                      ),
                    ),
                    if (profileDeepLink != null) ...[
                      Gap(36.h),
                      GestureDetector(
                        onLongPressStart: (_) {
                          isHolding.value = true;
                          captureAndShareQr();
                        },
                        onLongPressEnd: (_) {
                          isHolding.value = false;
                          dotCount.value = 0;
                          qrColorAnim.reverse();
                        },
                        onLongPressCancel: () {
                          isHolding.value = false;
                          dotCount.value = 0;
                          qrColorAnim.reverse();
                        },
                        child: RepaintBoundary(
                          key: qrRepaintKey,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 256.w),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: AnimatedBuilder(
                                  animation: qrColor,
                                  builder: (context, _) => QrImageView(
                                    key: ValueKey<String>(profileDeepLink),
                                    data: profileDeepLink,
                                    padding: EdgeInsets.zero,
                                    backgroundColor: colors.backgroundSecondary,
                                    eyeStyle: QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: qrColor.value ?? colors.backgroundContentPrimary,
                                    ),
                                    dataModuleStyle: QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: qrColor.value ?? colors.backgroundContentPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else
                    Gap(32.h),
                  Gap(12.h),
                  Text(
                    isHolding.value
                        ? '${context.l10n.holdToShareQrCode}${'.' * dotCount.value}'
                        : context.l10n.scanToConnect,
                    textAlign: TextAlign.center,
                    style: typography.medium14.copyWith(
                      color: colors.backgroundContentSecondary,
                      height: 1,
                    ),
                  ),
                  Gap(48.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: SizedBox(
                      width: double.infinity,
                      child: WnButton(
                        key: const Key('scan_qr_button'),
                        text: context.l10n.scanNpub,
                        type: WnButtonType.outline,
                        trailingIcon: WnIcons.scan,
                        size: WnButtonSize.medium,
                        onPressed: () => Routes.pushToScanNpub(context),
                      ),
                    ),
                  ),
                  Gap(16.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
