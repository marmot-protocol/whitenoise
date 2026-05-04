import 'package:flutter/material.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

class OfflineSystemNotice extends StatelessWidget {
  const OfflineSystemNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return WnSystemNotice(
      key: const Key('offline_notice'),
      title: context.l10n.waitingForInternet,
      type: WnSystemNoticeType.warning,
      variant: WnSystemNoticeVariant.expanded,
    );
  }
}
