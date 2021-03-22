import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:permission_handler/permission_handler.dart';
import 'package:signature_app/painter.dart';

class MyHomePage extends StatefulWidget {

 

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //  List<Offset> _points = <Offset>[];
   GlobalKey<_SignaturePadState> signatureKey;
   var image;
   Color newColor = Colors.black;

 @override
   void initState() {
     super.initState();

     signatureKey = GlobalKey<_SignaturePadState>();
     SystemChrome.setPreferredOrientations([
       DeviceOrientation.landscapeRight,
       DeviceOrientation.landscapeLeft,
     ]);

   }

   @override
     void dispose() {
       super.dispose();
        SystemChrome.setPreferredOrientations([
       DeviceOrientation.landscapeRight,
       DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
       DeviceOrientation.portraitDown,

     ]);
     }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(),
      body: Row(
        children: [
          Expanded(child: SignaturePad(key: signatureKey,)),
          Container(
            color: Colors.grey[300],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                   ElevatedButton(
                      onPressed:(){signatureKey.currentState.increaseBrush();},
                      child: Icon(Icons.brush_sharp),),
                       ElevatedButton(
                      onPressed: changeColor, 
                      child: Icon(Icons.color_lens)),
                    ElevatedButton(
                      onPressed: (){signatureKey.currentState.erasePoint();}, 
                      child: Icon(Icons.clear)),
                      // TODO: Save Signature Image to device
                    ElevatedButton(
                      onPressed:()=> setRenderedImage(context), 
                      child: Icon(Icons.save),),
                  ],
                ),
              ),
            ),
          )
        ],
      ));
  }
  

   void changeColor() async {
    Color selectedColor = newColor;
     showDialog(
       context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text('Pick a color'),
          content: SingleChildScrollView(
            child:  ColorPicker(
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
    pickerColor: newColor,
    onColorChanged: (color)=> selectedColor = color,
  )
          ),
          actions: [
             TextButton(
                 onPressed: ()=> Navigator.pop(context),
                  child: Text('Cancel')),

            TextButton(onPressed: (){
               setState(() => newColor = selectedColor);
               signatureKey.currentState.changeColor(newColor);
               setState(() {});
               Navigator.pop(context);
               }, 
               child: Text('Ok')),
              
          ],
   
        );
      });
     
     
  
   }

  

   Future<bool> checkPermission() async {
    return Permission.storage.isGranted;
   }
  Future<PermissionStatus> requestPermision() async {
   return  Permission.storage.request();
  }
   setRenderedImage(BuildContext context) async {
    ui.Image renderedImage = await signatureKey.currentState.rendered;

    setState(() {
      image = renderedImage;
    });

    showImage(context);
  }

  

  Future<Null> showImage(BuildContext context) async {
    final directoryName = 'Signature App';
    DateTime dateTime = DateTime.now();
    var pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if(!(await checkPermission())) await requestPermision();
    Directory directory = await getExternalStorageDirectory();
    String path = directory.path;
    print(path);
    await Directory('$path/$directoryName').create(recursive: true);
    File('$path/$directoryName/${dateTime.millisecond}.png')
        .writeAsBytesSync(pngBytes.buffer.asInt8List());


    return showDialog<Null>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Please check your device\'s Signature folder',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w300,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1.1
              ),
            ),
            content: Image.memory(Uint8List.view(pngBytes.buffer)),
          );
        }
    );
  }

}
class SignaturePad extends StatefulWidget {
   SignaturePad({Key key}) : super(key: key);
   

  @override
  _SignaturePadState createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
   List<Offset> _points = <Offset>[];
   double width = 10;  
   Color newColor = Colors.black;

   Future<ui.Image> get rendered{
     ui.PictureRecorder recorder =ui.PictureRecorder();
     Canvas canvas = Canvas(recorder);
     SignatureCanva signature =SignatureCanva(points: _points);
     var size = context.size;
     signature.paint(canvas, size);
     return recorder.endRecording().toImage(size.width.floor(), size.height.floor());
   }
   void erasePoint(){
     _points.clear();
   }
   void increaseBrush(){
     setState(() {
            width =  width !=5?5:10;
          });
     

     //TODO : increase/change size of brush

   }
   void changeColor(Color color) async {
     setState(() {
            newColor = color;
          });
   
   }


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        body: Container(
          child: GestureDetector(
            onPanUpdate: (DragUpdateDetails details){
              setState(() {
                RenderBox object = context.findRenderObject();
                Offset _localPosition = object.globalToLocal(details.globalPosition);
                _points = new List.from(_points)..add(_localPosition);

              });
            },
            onPanEnd: (DragEndDetails details)=> _points.add(null),
            child: CustomPaint(
              painter: SignatureCanva(points: _points, width: width, color: newColor),
              size: Size.infinite,
            ),
          )));
  }
}