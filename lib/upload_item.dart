import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class UploadItem extends StatefulWidget {
  const UploadItem({
    Key? key,
    required this.file,
    required this.send,
    required this.total,
  }) : super(key: key);

  final PlatformFile file;
  final int send;
  final int total;

  @override
  State<UploadItem> createState() => _UploadItemState();
}

class _UploadItemState extends State<UploadItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: SizedBox(
              width: 180,
              child: Text(widget.file.name),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            height: 8,
            child: LinearProgressIndicator(
              value: widget.send.toDouble() / widget.total.toDouble(),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 48,
            alignment: Alignment.center,
            child: widget.send >= widget.total
                ? const Icon(Icons.check)
                : Text(_getPercentage()),
          ),
        ],
      ),
    );
  }

  String _getPercentage() {
    final percentage = widget.send / widget.total;
    return '${(percentage * 100).toStringAsFixed(0)}%';
  }
}
