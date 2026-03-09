import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:gap/gap.dart' show Gap;
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_auth_buttons_container.dart' show WnAuthButtonsContainer;
import 'package:whitenoise/widgets/wn_slate.dart' show WnSlate;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svgs/whitenoise.svg',
                          width: 160.w,
                          height: 123.h,
                          colorFilter: ColorFilter.mode(
                            colors.backgroundContentPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                        Gap(24.h),
                        _RotatingSloganText(
                          texts: [
                            context.l10n.sloganDecentralized,
                            context.l10n.sloganUncensorable,
                            context.l10n.sloganSecureMessaging,
                          ],
                          style: typography.bold36.copyWith(
                            color: colors.backgroundContentTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            WnSlate(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
                child: const WnAuthButtonsContainer(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RotatingSloganText extends HookWidget {
  _RotatingSloganText({required this.texts, this.style})
    : assert(texts.isNotEmpty, 'texts must not be empty');

  static const _interval = Duration(seconds: 3);
  static const _animationDuration = Duration(milliseconds: 500);

  final List<String> texts;
  final TextStyle? style;

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
        style: style,
      ),
    );
  }
}
