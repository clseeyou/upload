import 'config.dart';

const apk = 'apk';
const ipa = 'ipa';
const plist = 'plist';
const png = 'png';

String getUploadPath(String fileName) {
  return '$fileDir/$fileName';
}

String getAndroidQrcodePath(String fileName) {
  return '$fileDir/$fileName';
}

String getIOSQrcodePath(String fileName) {
  return 'itms-services://?action=download-manifest&url=$fileDir/${fileName.replaceAll(ipa, plist)}';
}

String getQrcodeSavePath(
  String fileName, {
  required bool android,
}) {
  return '${fileName.substring(0, fileName.indexOf('.'))}-${android ? 'android' : 'ios'}.png';
}
