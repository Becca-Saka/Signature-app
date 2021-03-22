
import 'package:flutter/material.dart';

class SignatureCanva extends CustomPainter{
  final List<Offset> points;
  final double width;
  final Color color;
  

  SignatureCanva({this.points,  this.width, this.color});

  
  

  @override
  void paint(Canvas canvas, Size size) {

     Paint paint = new Paint()
     ..color = color
     ..strokeCap = StrokeCap.round
     ..style = PaintingStyle.stroke
     ..strokeWidth = width;
     


    for(int i = 0; i < points.length - 1; i++ ) {

      if(points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);

      }
    }
  }

  @override
  bool shouldRepaint(SignatureCanva oldDelegate)=>oldDelegate.points != points;

}
