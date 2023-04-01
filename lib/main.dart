import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
              height: 48,
            ),
            ..._files.map(
              (progressFile) => UploadItem(
                file: progressFile.file,
                send: progressFile.send,
                total: progressFile.total,
              ),
            ),
            const SizedBox(
              height: 48,
            ),
            Row(
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
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: QrcodeImage(
            qrcodeText: android
                ? getAndroidQrcodePath(fileName)
                : getIOSQrcodePath(fileName),
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        Text(
          fileName,
          style: const TextStyle(fontSize: 16),
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
}
