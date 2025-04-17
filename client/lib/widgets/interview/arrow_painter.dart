import 'package:flutter/material.dart';

class ArrowPainter extends CustomPainter {
  final Color color;
  
  ArrowPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    
    // Draw arrow point
    final point = Path();
    point.moveTo(0, size.height);
    point.lineTo(size.width / 2, 0);
    point.lineTo(size.width, size.height);
    
    // Draw horizontal line
    final horizontal = Path();
    horizontal.moveTo(size.width / 2, 0);
    horizontal.lineTo(size.width * 2, 0);
    
    canvas.drawPath(point, paint);
    canvas.drawPath(horizontal, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}