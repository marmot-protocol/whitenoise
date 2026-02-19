import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/utils/formatting.dart' show formatInitials;
import 'package:whitenoise/widgets/wn_icon.dart';

export 'package:whitenoise/utils/avatar_color.dart';

enum WnAvatarSize { bubble, xSmall, small, medium, large }

class WnAvatar extends HookWidget {
  const WnAvatar({
    super.key,
    this.pictureUrl,
    this.displayName,
    this.size = WnAvatarSize.small,
    this.imageProvider,
    this.color = AvatarColor.neutral,
    this.onEditTap,
    this.showPinned = false,
  });

  final String? pictureUrl;
  final String? displayName;
  final WnAvatarSize size;
  final ImageProvider? imageProvider;
  final AvatarColor color;
  final VoidCallback? onEditTap;
  final bool showPinned;

  double _getAvatarSize() {
    return switch (size) {
      WnAvatarSize.bubble => 20.w,
      WnAvatarSize.xSmall => 36.w,
      WnAvatarSize.small => 48.w,
      WnAvatarSize.medium => 56.w,
      WnAvatarSize.large => 96.w,
    };
  }

  double _getFontSize() {
    return switch (size) {
      WnAvatarSize.bubble => 8.sp,
      WnAvatarSize.xSmall => 12.sp,
      WnAvatarSize.small => 14.sp,
      WnAvatarSize.medium => 16.sp,
      WnAvatarSize.large => 32.sp,
    };
  }

  double _getIconSize() {
    return switch (size) {
      WnAvatarSize.bubble => 10.w,
      WnAvatarSize.xSmall => 14.w,
      WnAvatarSize.small => 16.w,
      WnAvatarSize.medium => 20.w,
      WnAvatarSize.large => 32.w,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final avatarSize = _getAvatarSize();
    final fontSize = _getFontSize();
    final iconSize = _getIconSize();

    final colorSet = color.toColorSet(colors);

    final image = useMemoized(() {
      if (imageProvider != null) return imageProvider;
      final url = pictureUrl;
      if (url == null || url.isEmpty) return null;
      final isUrl = url.startsWith('http://') || url.startsWith('https://');
      if (isUrl) {
        return CachedNetworkImageProvider(url);
      }
      return FileImage(File(url));
    }, [pictureUrl, imageProvider]);

    final avatarWidget = image == null
        ? _InitialsAvatar(
            displayName: displayName,
            size: avatarSize,
            fontSize: fontSize,
            iconSize: iconSize,
            colorSet: colorSet,
            avatarSizeEnum: size,
          )
        : _ImageAvatar(
            image: image,
            displayName: displayName,
            size: avatarSize,
            fontSize: fontSize,
            iconSize: iconSize,
            colorSet: colorSet,
            avatarSizeEnum: size,
          );

    final showEditButton = onEditTap != null && size == WnAvatarSize.large;
    final showPinBadge = showPinned && size == WnAvatarSize.medium;

    return Stack(
      children: [
        avatarWidget,
        if (showEditButton)
          Positioned(
            right: 0,
            bottom: 0,
            child: _EditButton(onTap: onEditTap!),
          ),
        if (showPinBadge)
          const Positioned(
            right: 0,
            bottom: 0,
            child: _PinBadge(),
          ),
      ],
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final buttonSize = 28.w;
    final iconSize = 24.w;

    return GestureDetector(
      key: const Key('avatar_edit_button'),
      onTap: onTap,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.backgroundSecondary,
        ),
        child: Center(
          child: WnIcon(
            WnIcons.editCircle,
            size: iconSize,
            color: colors.backgroundContentPrimary,
          ),
        ),
      ),
    );
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final badgeSize = 18.w;
    final iconSize = 16.w;

    return Container(
      key: const Key('avatar_pin_badge'),
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.backgroundSecondary,
      ),
      child: Center(
        child: WnIcon(
          WnIcons.pinFilled,
          size: iconSize,
          color: colors.backgroundContentSecondary,
        ),
      ),
    );
  }
}

class _InitialsContent extends StatelessWidget {
  const _InitialsContent({
    this.displayName,
    required this.fontSize,
    required this.iconSize,
    required this.contentColor,
    required this.avatarSizeEnum,
  });

  final String? displayName;
  final double fontSize;
  final double iconSize;
  final Color contentColor;
  final WnAvatarSize avatarSizeEnum;

  @override
  Widget build(BuildContext context) {
    final typography = context.typographyScaled;
    final initials = formatInitials(displayName);

    final textStyle = switch (avatarSizeEnum) {
      WnAvatarSize.bubble => typography.semiBold12,
      WnAvatarSize.xSmall => typography.semiBold12,
      WnAvatarSize.small => typography.semiBold14,
      WnAvatarSize.medium => typography.semiBold16,
      WnAvatarSize.large => typography.semiBold32,
    };

    return Center(
      child: initials != null
          ? Text(
              initials,
              style: textStyle.copyWith(color: contentColor),
            )
          : WnIcon(
              WnIcons.user,
              size: iconSize,
              color: contentColor,
            ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    this.displayName,
    required this.size,
    required this.fontSize,
    required this.iconSize,
    required this.colorSet,
    required this.avatarSizeEnum,
  });

  final String? displayName;
  final double size;
  final double fontSize;
  final double iconSize;
  final AvatarColorSet colorSet;
  final WnAvatarSize avatarSizeEnum;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('avatar_container'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorSet.background,
        border: Border.all(color: colorSet.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: _InitialsContent(
        displayName: displayName,
        fontSize: fontSize,
        iconSize: iconSize,
        contentColor: colorSet.content,
        avatarSizeEnum: avatarSizeEnum,
      ),
    );
  }
}

class _AvatarContainer extends StatelessWidget {
  const _AvatarContainer({
    required this.size,
    required this.child,
  });

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.backgroundPrimary,
        border: Border.all(color: colors.borderTertiary),
      ),
      child: ClipOval(child: child),
    );
  }
}

class _ImageAvatar extends HookWidget {
  const _ImageAvatar({
    required this.image,
    this.displayName,
    required this.size,
    required this.fontSize,
    required this.iconSize,
    required this.colorSet,
    required this.avatarSizeEnum,
  });

  final ImageProvider image;
  final String? displayName;
  final double size;
  final double fontSize;
  final double iconSize;
  final AvatarColorSet colorSet;
  final WnAvatarSize avatarSizeEnum;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLoading = useState(true);
    final hasError = useState(false);
    final previousImage = useRef<ImageProvider?>(null);

    useEffect(() {
      isLoading.value = true;
      hasError.value = false;

      final imageStream = image.resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener(
        (_, _) {
          isLoading.value = false;
          previousImage.value = image;
        },
        onError: (_, _) {
          isLoading.value = false;
          hasError.value = true;
        },
      );
      imageStream.addListener(listener);

      return () => imageStream.removeListener(listener);
    }, [image]);

    if (hasError.value && previousImage.value == null) {
      return _InitialsAvatar(
        displayName: displayName,
        size: size,
        fontSize: fontSize,
        iconSize: iconSize,
        colorSet: colorSet,
        avatarSizeEnum: avatarSizeEnum,
      );
    }

    return _AvatarContainer(
      size: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: colors.backgroundPrimary,
            child: _InitialsContent(
              displayName: displayName,
              fontSize: fontSize,
              iconSize: iconSize,
              contentColor: colors.backgroundContentSecondary,
              avatarSizeEnum: avatarSizeEnum,
            ),
          ),
          if (previousImage.value != null)
            Image(
              image: previousImage.value!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
            opacity: isLoading.value ? 0.0 : 1.0,
            child: Image(
              image: image,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
