import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkIfPackIsDownloaded(String moduleCode) async{
  bool allowed = await checkPermission();
  if (allowed){
    bool packIsExist = await Directory(moduleCode).exists();
    if (packIsExist){
      print('pack is exist!');
      return true;
    } else {
      print('pack is not yet exist!');
      return false;
    }
  } else {
    return false;
  }
}

// use some kotlin OR flutter lib to do download from playstore expansion pack
// on success downloading, extract zip to shared memory

Future<bool> downloadPack(String moduleCode) async {

}

Future<bool> checkPermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted){
      return true;
    } else {
      return false;
    }
  } else {
    return true;
  }
}
