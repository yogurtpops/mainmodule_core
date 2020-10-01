import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:fluttermodular/mainmodule/view/landing_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

final bool debug = true;

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

  startDownloadFile() async {
    _requestDownload();
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

  List<_TaskInfo> _tasks;
  // List<_ItemHolder> _items;
  bool _isLoading;
  bool _permissionReady;
  String _localPath;
  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
    checkIfImageEditorModuleFileExist();
    platform.setMethodCallHandler((call) {
      print('platform channel method call ${call.method} ${call.arguments}');
      if (call.method=="updateDownloadState"){
        setState(() {
          statusText = call.arguments;
        });
        if (call.arguments==EXTRACT_FAILED){
          Modular.to.pop();
        } else if (call.arguments==DONE_EXTRACT){
          setState(() {
            statusText = "Extracting success";
          });
          Modular.to.pushReplacementNamed("/imageeditor");
        } else if (call.arguments==START_EXTRACT){
          setState(() {
            statusText = "Extracting downloaded files...";
          });
        }
      }
    });
  }

  checkIfImageEditorModuleFileExist() async {
    bool downloadPackExist = await checkIfPackIsDownloaded(DOWNLOADED_IMAGE_MODULE_EDITOR_EXPANSION_PACK_ACCESS_CODE);
    if (downloadPackExist){
      print('pack is downloaded');
      bool extractedPackExist = await checkIfPackIsDownloaded(IMAGE_MODULE_EDITOR_EXPANSION_PACK_ACCESS_CODE);
      if (extractedPackExist){
        print('pack is extracted');
        Modular.to.pushReplacementNamed('/imageeditor').then((value) => setState((){
          _isLoading = false;
        }));
      } else {
        print('pack not yet extracted');
        connectToService();
      }
    } else {
      print('pack not yet downloaded');
      setState(() {
        statusText = "Downloading assets...";
      });
      startDownloadFile();
    }
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      if (debug) {
        print('UI Isolate Callback: ${data[1].toString()}');
      }
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];

      final task = _tasks?.firstWhere((task) => task.taskId == id);
      if (task != null) {
        setState(() {
          task.status = status;
          task.progress = progress;
        });
      }

      if (data[1]==DownloadTaskStatus.complete || data[1]==DownloadTaskStatus.failed){
        print('UI Isolate Callback: kompleeeet');
        connectToService();
      }

    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    if (debug) {
      print(
          'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    }
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  void _requestDownload() async {
    await Directory('/storage/emulated/0/Android/obb').create();
    await Directory('/storage/emulated/0/Android/obb/com.dididi.basictomodular').create();
    var id = await FlutterDownloader.enqueue(
      url: 'https://drive.google.com/u/0/uc?id=1WEFfdeGiS5J1ZJIGCW_JMbSvLid4A_Ma&export=download',
      savedDir: '/storage/emulated/0/Android/obb/com.dididi.basictomodular',
      showNotification: true, // show download progress in status bar (for Android)
      openFileFromNotification: true, // click// on notification to open downloaded file (for Android)
    );
  }

  void _cancelDownload(_TaskInfo task) async {
    await FlutterDownloader.cancel(taskId: task.taskId);
  }

  void _pauseDownload(_TaskInfo task) async {
    await FlutterDownloader.pause(taskId: task.taskId);
  }

  void _resumeDownload(_TaskInfo task) async {
    String newTaskId = await FlutterDownloader.resume(taskId: task.taskId);
    task.taskId = newTaskId;
  }

  void _retryDownload(_TaskInfo task) async {
    String newTaskId = await FlutterDownloader.retry(taskId: task.taskId);
    task.taskId = newTaskId;
  }

  Future<bool> _openDownloadedFile(_TaskInfo task) {
    return FlutterDownloader.open(taskId: task.taskId);
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.storage.status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.storage.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  // Future<Null> _prepare() async {
  //   final tasks = await FlutterDownloader.loadTasks();
  //
  //   int count = 0;
  //   _tasks = [];
  //   _items = [];
  //
  //   _tasks.addAll(_documents.map((document) =>
  //       _TaskInfo(name: document['name'], link: document['link'])));
  //
  //   _items.add(_ItemHolder(name: 'Documents'));
  //   for (int i = count; i < _tasks.length; i++) {
  //     _items.add(_ItemHolder(name: _tasks[i].name, task: _tasks[i]));
  //     count++;
  //   }
  //
  //   _tasks.addAll(_images
  //       .map((image) => _TaskInfo(name: image['name'], link: image['link'])));
  //
  //   _items.add(_ItemHolder(name: 'Images'));
  //   for (int i = count; i < _tasks.length; i++) {
  //     _items.add(_ItemHolder(name: _tasks[i].name, task: _tasks[i]));
  //     count++;
  //   }
  //
  //   _tasks.addAll(_videos
  //       .map((video) => _TaskInfo(name: video['name'], link: video['link'])));
  //
  //   _items.add(_ItemHolder(name: 'Videos'));
  //   for (int i = count; i < _tasks.length; i++) {
  //     _items.add(_ItemHolder(name: _tasks[i].name, task: _tasks[i]));
  //     count++;
  //   }
  //
  //   tasks?.forEach((task) {
  //     for (_TaskInfo info in _tasks) {
  //       if (info.link == task.url) {
  //         info.taskId = task.taskId;
  //         info.status = task.status;
  //         info.progress = task.progress;
  //       }
  //     }
  //   });
  //
  //   _permissionReady = await _checkPermission();
  //
  //   _localPath = (await _findLocalPath()) + Platform.pathSeparator + 'Download';
  //
  //   final savedDir = Directory(_localPath);
  //   bool hasExisted = await savedDir.exists();
  //   if (!hasExisted) {
  //     savedDir.create();
  //   }
  //
  //   setState(() {
  //     _isLoading = false;
  //   });
  // }

  // Future<String> _findLocalPath() async {
  //   final directory = widget.platform == TargetPlatform.android
  //       ? await getExternalStorageDirectory()
  //       : await getApplicationDocumentsDirectory();
  //   return directory.path;
  // }


  String statusText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Modular App'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Center(
            child: CircularProgressIndicator(),
          ),
          Padding(
            padding: const EdgeInsets.only(top:68.0),
            child: Text(statusText),
          )
        ],
      ),
    );
  }
}

class _TaskInfo {
  final String name;
  final String link;

  String taskId;
  int progress = 0;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;

  _TaskInfo({this.name, this.link});
}

String NO_FILE = "no_file_to_download";
String DONE_EXTRACT = "done_extraxt";
String EXTRACT_FAILED = "extract_failed";
String START_EXTRACT = "start_extraxt";