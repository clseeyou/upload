import 'package:file_picker/file_picker.dart';

class ProgressFile {
  PlatformFile file;
  int send;
  int total;

  ProgressFile(
    this.file,
    this.send,
    this.total,
  );
}
