import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static Future<bool> ensureLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> ensureMic() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
}
