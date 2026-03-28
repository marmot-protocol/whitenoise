import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum WnIcons {
  addCircle('add_circle'),
  addEmoji('add_emoji'),
  addFilled('add_filled'),
  addLarge('add_large'),
  appearance('appearance'),
  apple('apple'),
  archive('archive'),
  arrowDown('arrow_down'),
  arrowLeft('arrow_left'),
  arrowRight('arrow_right'),
  arrowUp('arrow_up'),
  beeBat('bee_bat'),
  bitcoin('bitcoin'),
  building('building'),
  change('change'),
  checkbox('checkbox'),
  checkboxChecked('checkbox_checked'),
  checkmark('checkmark'),
  checkmarkDashed('checkmark_dashed'),
  checkmarkFilled('checkmark_filled'),
  checkmarkOutline('checkmark_outline'),
  chevronDown('chevron_down'),
  chevronLeft('chevron_left'),
  chevronRight('chevron_right'),
  chevronUp('chevron_up'),
  clean('clean'),
  closeLarge('close_large'),
  closeSmall('close_small'),
  copy('copy'),
  dataUsage('data_usage'),
  developerSettings('developer_settings'),
  download('download'),
  edit('edit'),
  editCircle('edit_circle'),
  editSettings('edit_settings'),
  error('error'),
  errorFilled('error_filled'),
  faceSatisfied('face_satisfied'),
  file('file'),
  flag('flag'),
  forward('forward'),
  hashtag('hashtag'),
  heart('heart'),
  help('help'),
  helpChat('help_chat'),
  helpFilled('help_filled'),
  idea('idea'),
  image('image'),
  information('information'),
  informationFilled('information_filled'),
  key('key'),
  leave('leave'),
  logout('logout'),
  makeAdmin('make_admin'),
  message('message'),
  more('more'),
  network('network'),
  newChat('new_chat'),
  newGroupChat('new_group_chat'),
  notification('notification'),
  notificationOff('notification_off'),
  notificationsTurnedOff('notifications_turned_off'),
  paste('paste'),
  pin('pin'),
  pinFilled('pin_filled'),
  placeholder('placeholder'),
  plus('plus'),
  privacy('privacy'),
  qrCode('qr_code'),
  removeAdmin('remove_admin'),
  removeCircle('remove_circle'),
  reset('reset'),
  reply('reply'),
  retry('retry'),
  running('running'),
  scan('scan'),
  search('search'),
  selectText('select_text'),
  settings('settings'),
  time('time'),
  trashCan('trash_can'),
  unarchive('unarchive'),
  unpin('unpin'),
  user('user'),
  userFollow('user_follow'),
  userUnfollow('user_unfollow'),
  view('view'),
  viewOff('view_off'),
  warning('warning'),
  warningFilled('warning_filled'),
  zap('zap')
  ;

  const WnIcons(this.filename);
  final String filename;

  String get path => 'assets/svgs/$filename.svg';
}

class WnIcon extends StatelessWidget {
  const WnIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
  });

  final WnIcons icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 24.w;
    final resolvedColor = color ?? IconTheme.of(context).color;
    return SvgPicture.asset(
      icon.path,
      width: s,
      height: s,
      colorFilter: resolvedColor != null ? ColorFilter.mode(resolvedColor, BlendMode.srcIn) : null,
    );
  }
}
