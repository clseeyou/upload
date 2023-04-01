import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrcodeImage extends StatefulWidget {
  const QrcodeImage({
    Key? key,
    required this.qrcodeText,
  }) : super(key: key);

  final String qrcodeText;

  @override
  State<StatefulWidget> createState() => _QrcodeImageState();
}

class _QrcodeImageState extends State<QrcodeImage> {
  final _size = 1000.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: _createQRImage(),
    );
  }

  Widget _createQRImage() {
    final logoSize = _size / 5;
    return QrImage(
      data: widget.qrcodeText,
      size: _size,
      embeddedImage: const AssetImage('assets/images/logo.jpg'),
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
}
