import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:gap/gap.dart';
import 'package:whitenoise/theme.dart';

class WnLogoSlogan extends StatelessWidget {
  const WnLogoSlogan({
    super.key,
    required this.texts,
    this.logoKey = const ValueKey('whitenoise_logo'),
  });

  final List<String> texts;
  final Key logoKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        SvgPicture.asset(
          key: logoKey,
          'assets/svgs/whitenoise.svg',
          width: 160.w,
          height: 123.h,
          colorFilter: ColorFilter.mode(
            colors.backgroundContentPrimary,
            BlendMode.srcIn,
          ),
        ),
        Gap(24.h),
        _WnRotatingSloganText(
          texts: texts,
        ),
      ],
    );
  }
}

class _WnRotatingSloganText extends HookWidget {
  const _WnRotatingSloganText({required this.texts});

  static const _interval = Duration(seconds: 3);
  static const _animationDuration = Duration(milliseconds: 500);

  final List<String> texts;

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(0);
    final timerRef = useRef<Timer?>(null);

    useEffect(() {
      timerRef.value = Timer.periodic(_interval, (_) {
        currentIndex.value = (currentIndex.value + 1) % texts.length;
      });
      return () => timerRef.value?.cancel();
    }, [texts.length]);

    return AnimatedSwitcher(
      duration: _animationDuration,
      switchInCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      switchOutCurve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: Text(
        texts[currentIndex.value],
        key: ValueKey<int>(currentIndex.value),
        textAlign: TextAlign.center,
        style: context.typographyScaled.bold36.copyWith(
          color: context.colors.backgroundContentTertiary,
        ),
      ),
    );
  }
}
