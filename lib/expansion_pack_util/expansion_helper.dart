import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkIfPackIsDownloaded(String moduleCode) async{
  bool allowed = await checkPermission(Permission.storage);
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

Future<bool> checkPermission(Permission permission) async {
  var status = await permission.status;
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

class ExpansionDownloadPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateExpansionDownloadPage();
  }
}

class StateExpansionDownloadPage extends State<ExpansionDownloadPage> {
  static const platform = MethodChannel('basictomodular/downloadservice');

  Future<void> connectToService() async {
    try {
      final result = await platform.invokeMethod<String>('connect');
      print('Connected to service platform result is ${result}');
      if (result == NO_FILE){
        Modular.to.pop();
      } else {

      }
    } on Exception catch (e) {
      print('invoke method'+e.toString());
    }
  }

  Future<String> getDataFromService() async {
    try {
      final result = await platform.invokeMethod<String>('start');
      return result;
    } on PlatformException catch (e) {
      print(e.toString());
    }
    return 'No Data From Service';
  }

  @override
  void initState() {
    super.initState();
    connectToService();

    platform.setMethodCallHandler((call) {
      print('platform channel method call ${call.method} ${call.arguments}');
      if (call.method=="updateDownloadState"){
        Fluttertoast.showToast(
            msg: call.arguments,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
        );
        if (call.arguments=="STATE_COMPLETED"){
          print('download complete');
          Modular.to.pop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

String NO_FILE = "no_file_to_download";
