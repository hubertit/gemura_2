import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_theme.dart';

class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? textColor;

  const MarkdownText({
    Key? key,
    required this.text,
    this.style,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? const TextStyle(fontSize: 14);
    final color = textColor ?? AppTheme.textPrimaryColor;
    
    return MarkdownBody(
      data: text,
      styleSheet: MarkdownStyleSheet(
        p: defaultStyle.copyWith(color: color),
        strong: defaultStyle.copyWith(color: color, fontWeight: FontWeight.bold),
        em: defaultStyle.copyWith(color: color, fontStyle: FontStyle.italic),
        code: defaultStyle.copyWith(
          color: color, 
          backgroundColor: Colors.black.withOpacity(0.1),
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        listBullet: defaultStyle.copyWith(color: color),
        h1: defaultStyle.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 18),
        h2: defaultStyle.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        h3: defaultStyle.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        blockquote: defaultStyle.copyWith(
          color: color.withOpacity(0.8),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color.withOpacity(0.3), width: 3),
          ),
        ),
      ),
      shrinkWrap: true,
      softLineBreak: true,
    );
  }
} 