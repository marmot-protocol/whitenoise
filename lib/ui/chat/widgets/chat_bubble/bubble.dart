import 'package:flutter/material.dart';
import 'package:whitenoise/ui/chat/widgets/chat_bubble/painter.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';

class ChatMessageBubble extends StatelessWidget {
  final bool isSender;
  final Widget child;
  final bool tail;
  final Color? color;
  final BoxConstraints? constraints;

  const ChatMessageBubble({
    super.key,
    this.isSender = true,
    this.constraints,
    required this.child,
    this.tail = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints:
                constraints ??
                BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
            child: CustomPaint(
              painter: CustomChatBubbleNoBorderPainter(
                color: color ?? context.colors.meChatBubble,
                alignment: isSender ? Alignment.topRight : Alignment.topLeft,
                tail: tail,
              ),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
                padding: EdgeInsets.only(
                  left: 2.w,
                  right: 2.w,
                  top: 2.h,
                  bottom: 6.h,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
