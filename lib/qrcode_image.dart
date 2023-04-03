import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrcodeImage extends StatefulWidget {
  const QrcodeImage({
    Key? key,
    required this.qrcodeText,
    required this.android,
    this.version,
    required this.size,
  }) : super(key: key);

  final String qrcodeText;
  final bool android;
  final String? version;
  final double size;

  @override
  State<StatefulWidget> createState() => QrcodeImageState();
}

class QrcodeImageState extends State<QrcodeImage> {
  final assetPath = 'assets/images/logo.jpg';

  Uint8List? logoBytes;
  ui.Image? logoImage;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    var image = await (widget.key as GlobalKey<QrcodeImageState>)
        .currentState
        ?.getRenderedImage(
          assetPath: assetPath,
          android: widget.android,
          version: widget.version,
          size: Size(widget.size / 5, widget.size / 5),
        );
    var pngBytes = await image?.toByteData(format: ui.ImageByteFormat.png);

    setState(() {
      logoBytes = pngBytes?.buffer.asUint8List();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _createQRImage();
  }

  Widget _createQRImage() {
    if (logoBytes == null) {
      return const SizedBox();
    }

    final size = widget.size;
    final logoSize = size / 5;
    return QrImage(
      data: widget.qrcodeText,
      size: size,
      embeddedImage: MemoryImage(logoBytes!),
      embeddedImageStyle: QrEmbeddedImageStyle(
        size: Size(logoSize, logoSize),
      ),
      errorStateBuilder: (cxt, err) {
        return const Center(
          child: Text(
            "生成二维码失败",
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Future<ui.Image> _loadUiImage(String imageAssetPath) async {
    final ByteData data = await rootBundle.load(imageAssetPath);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  Future<ui.Image> getRenderedImage({
    required String assetPath,
    required bool android,
    String? version,
    required Size size,
  }) async {
    final logoImage = await _loadUiImage(assetPath);

    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    _drawLogo(canvas, size, logoImage);
    _drawPlatform(canvas, size, android);
    if (version != null) {
      _drawVersion(canvas, size, version);
    }
    return recorder
        .endRecording()
        .toImage(size.width.floor(), size.height.floor());
  }

  void _drawLogo(Canvas canvas, Size size, ui.Image logoImage) {
    final logoRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final logoPaint = Paint();
    logoPaint.isAntiAlias = true;
    logoPaint.filterQuality = FilterQuality.high;
    logoPaint.colorFilter = const ColorFilter.mode(
      Colors.white,
      BlendMode.dstIn,
    );

    canvas.drawImageRect(
      logoImage,
      Rect.fromLTWH(
        0,
        0,
        logoImage.width.toDouble(),
        logoImage.height.toDouble(),
      ),
      logoRect,
      logoPaint,
    );
  }

  void _drawPlatform(Canvas canvas, Size size, bool android) {
    final icon = android ? Icons.android : Icons.apple;

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: android ? Colors.green : Colors.grey,
          fontSize: 140,
          fontFamily: icon.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final xCenter = (size.width - textPainter.width) / 2;
    final yCenter = (size.height - textPainter.height) / 2;
    final offset = Offset(xCenter, yCenter);

    textPainter.paint(canvas, offset);
  }

  void _drawVersion(Canvas canvas, Size size, String? version) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: version,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    final xCenter = (size.width - textPainter.width);
    final yCenter = (size.height - textPainter.height);
    final offset = Offset(xCenter, yCenter);

    textPainter.paint(canvas, offset);
  }
}
