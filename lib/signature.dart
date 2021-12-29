import 'dart:io';
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
        body: Row(
      children: [
        Expanded(
            child: SignaturePad(
          key: signatureKey,
        )),
        Container(
          color: Colors.grey[300],
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      signatureKey.currentState.increaseBrush();
                    },
                    child: Icon(Icons.brush_sharp),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        signatureKey.currentState.changeColor();
                      },
                      child: Icon(Icons.color_lens)),
                  ElevatedButton(
                      onPressed: () {
                        signatureKey.currentState.erasePoint();
                      },
                      child: Icon(Icons.clear)),
                  ElevatedButton(
                    onPressed: () => setRenderedImage(context),
                    child: Icon(Icons.save),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    ));
  }

  Future<bool> checkPermission() async {
    return Permission.storage.isGranted;
  }

  Future<PermissionStatus> requestPermision() async {
    return Permission.storage.request();
  }

  setRenderedImage(BuildContext context) async {
    ui.Image renderedImage = await signatureKey.currentState.rendered;

    setState(() {
      image = renderedImage;
    });

    showImage();
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  void showImage() async {
    Directory directory;
    if (Platform.isAndroid) {
      if (await _requestPermission(Permission.storage) &&
          // access media location needed for android 10/Q
          await _requestPermission(Permission.accessMediaLocation) &&
          // manage external storage needed for android 11/R
          await _requestPermission(Permission.manageExternalStorage)) {
        directory = await getExternalStorageDirectory();
        String newPath = "";
        print(directory);
        List<String> paths = directory.path.split("/");
        for (int x = 1; x < paths.length; x++) {
          String folder = paths[x];
          if (folder != "Android") {
            newPath += "/" + folder;
          } else {
            break;
          }
        }
        newPath = newPath + "/Signature App";
        directory = Directory(newPath);
        if (!directory.existsSync()) {
          await directory.create(recursive: true);
        }
        DateTime dateTime = DateTime.now();
        final String filePath = '$newPath/Sig${dateTime.microsecond}.png';

        var pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
        print(filePath);
        File(filePath).writeAsBytesSync(pngBytes.buffer.asInt8List());
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Image Saved')));
      }
    }
    print(directory);
    // final directoryName = 'Signature App';
    // DateTime dateTime = DateTime.now();
    // var pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    // if (!(await checkPermission())) await requestPermision();
    // String path = '/storage/emulated/0/$directoryName';
    // final dir = Directory(path);
    // if (!dir.existsSync()) {
    //   await dir.create(recursive: true);
    // }
    // final String filePath = '$path/Sig${dateTime.microsecond}.png';
    // print(filePath);
    // File(filePath).writeAsBytesSync(pngBytes.buffer.asInt8List());
    // ScaffoldMessenger.of(context)
    //     .showSnackBar(SnackBar(content: Text('Image Saved')));
  }
}

class SignaturePad extends StatefulWidget {
  SignaturePad({Key key}) : super(key: key);

  @override
  _SignaturePadState createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  List<Offset> _points = <Offset>[];
  double width = 3;
  Color newColor = Colors.black;

  Future<ui.Image> get rendered {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    SignatureCanva signature =
        SignatureCanva(points: _points, width: width, color: newColor);
    var size = context.size;
    signature.paint(canvas, size);
    return recorder
        .endRecording()
        .toImage(size.width.floor(), size.height.floor());
  }

  void erasePoint() {
    _points.clear();
  }

  void increaseBrush() {
    setState(() {
      width = width != 3 ? 3 : 6;
    });
    //TODO : increase/change size of brush
  }

  void changeColor() async {
    Color selectedColor = newColor;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Pick a color'),
            content: SingleChildScrollView(
                child: ColorPicker(
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
              pickerColor: newColor,
              onColorChanged: (color) => selectedColor = color,
            )),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
              TextButton(
                  onPressed: () {
                    setState(() {
                      newColor = selectedColor;
                      erasePoint();
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Ok')),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            child: GestureDetector(
      onPanUpdate: (DragUpdateDetails details) {
        setState(() {
          RenderBox object = context.findRenderObject();
          Offset _localPosition = object.globalToLocal(details.globalPosition);
          _points = new List.from(_points)..add(_localPosition);
        });
      },
      onPanEnd: (DragEndDetails details) => _points.add(null),
      child: CustomPaint(
        painter: SignatureCanva(points: _points, width: width, color: newColor),
        size: Size.infinite,
      ),
    )));
  }
}
