import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:motion_toast/resources/arrays.dart';
import 'package:upload/path_utils.dart';
import 'package:upload/progress_file.dart';
import 'package:upload/qrcode_image.dart';
import 'package:upload/upload_item.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upload',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Upload App Files'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _qrCodeSize = 1000.0;
  final _qrImageSize = 200.0;
  final List<ProgressFile> _files = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(
              height: 32,
            ),
            ..._files.map(
              (progressFile) => UploadItem(
                file: progressFile.file,
                send: progressFile.send,
                total: progressFile.total,
              ),
            ),
            const SizedBox(
              height: 32,
            ),
            Visibility(
              visible: !_files.any((progressFile) {
                return progressFile.send < progressFile.total;
              }),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._files.map((progressFile) {
                    var extension = progressFile.file.extension;
                    if (extension == apk) {
                      return _qrcodeImage(
                        progressFile.file.name,
                        android: true,
                      );
                    } else if (extension == ipa) {
                      return _qrcodeImage(
                        progressFile.file.name,
                        android: false,
                      );
                    } else {
                      return Container();
                    }
                  }),
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadFiles,
        tooltip: 'Upload',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _qrcodeImage(
    String fileName, {
    required bool android,
  }) {
    GlobalKey qrcodeKey = GlobalKey();
    GlobalKey<QrcodeImageState> logoKey = GlobalKey();
    return Column(
      children: [
        Container(
          width: _qrImageSize,
          height: _qrImageSize,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: FittedBox(
            child: RepaintBoundary(
              key: qrcodeKey,
              child: Container(
                width: _qrCodeSize,
                height: _qrCodeSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: QrcodeImage(
                  key: logoKey,
                  qrcodeText: android
                      ? getAndroidQrcodePath(fileName)
                      : getIOSQrcodePath(fileName),
                  android: android,
                  version: getVersion(fileName),
                  size: _qrCodeSize,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        Text(
          fileName,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(
          height: 16,
        ),
        // 保存
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                Uint8List? bytes = await _captureWidget(qrcodeKey);
                await save(fileName, bytes: bytes, android: android);
                if (context.mounted) {
                  _toast(context, '保存成功');
                }
              },
              child: const Text('保存图片'),
            ),
            const SizedBox(
              width: 16,
            ),
            ElevatedButton(
              onPressed: () async {
                Clipboard.setData(ClipboardData(
                  text: android
                      ? getAndroidQrcodePath(fileName)
                      : getIOSQrcodePath(fileName),
                ));
                if (context.mounted) {
                  _toast(context, '复制成功');
                }
              },
              child: const Text('复制地址'),
            ),
          ],
        ),
      ],
    );
  }

  void _uploadFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [apk, ipa, plist],
      withData: false,
      withReadStream: true,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No file picked or file picker was cancelled');
    }

    _files
      ..clear()
      ..addAll(result.files.map((file) => ProgressFile(
            file,
            0,
            file.size,
          )));

    setState(() {});

    for (var file in _files) {
      upload(file);
    }
  }

  Future<void> upload(ProgressFile progressFile) async {
    final file = progressFile.file;
    final fileReadStream = file.readStream;

    final Dio dio = Dio();
    dio.interceptors.add(LogInterceptor(
      responseBody: true,
      requestBody: true,
      requestHeader: true,
      responseHeader: true,
    ));
    dio.options.headers = {
      'Content-Type': 'application/octet-stream',
      'Content-Length': file.size.toString(),
    };

    final response = await dio.put(
      getUploadPath(file.name),
      data: fileReadStream,
      onSendProgress: (int sent, int total) {
        setState(() {
          progressFile.send = sent;
        });
      },
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  Future<void> save(
    String fileName, {
    Uint8List? bytes,
    required bool android,
  }) async {
    String? outputFile = await FilePicker.platform.saveFile(
      fileName: getQrcodeSavePath(
        fileName,
        android: android,
      ),
      type: FileType.image,
      allowedExtensions: [png],
    );

    if (outputFile == null) {
      throw Exception('File picker was cancelled');
    }

    try {
      final file = File(outputFile);
      file.writeAsBytesSync(bytes ?? []);
    } catch (e) {
      throw Exception('File write error');
    }
  }

  Future<Uint8List?> _captureWidget(GlobalKey key) async {
    final RenderRepaintBoundary boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage();
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  void _toast(BuildContext context, String message) {
    MotionToast.success(
      description: Text(message),
      position: MotionToastPosition.center,
      animationDuration: const Duration(milliseconds: 200),
      toastDuration: const Duration(milliseconds: 500),
    ).show(context);
  }
}
