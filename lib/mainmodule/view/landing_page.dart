import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:fluttermodular/expansion_pack_util/expansion_helper.dart';
import 'file:///home/tlab-n024/project/utilmodule/lib/util/preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String IMAGE_MODULE_EDITOR_EXPANSION_PACK_ACCESS_CODE = "/storage/emulated/0/com.dididi.basictomodular";
final String DOWNLOADED_IMAGE_MODULE_EDITOR_EXPANSION_PACK_ACCESS_CODE = "/storage/emulated/0/Android/obb/com.dididi.basictomodular";

class LandingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateLandingPage();
  }
}

class SecondTab extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateSecondTab();
  }
}


class StateSecondTab extends State<SecondTab> {
  bool showLoading = false;
  final String METHOD_PLAYASSET = "playasset";
  final String KOTLIN_METHOD_GETASSET = "get_asset";
  String statusText="Mohon tunggu";
  static const platform = MethodChannel('basictomodular/downloadservice');

  @override
  void initState() async {
    prefs = await SharedPreferences.getInstance();
    platform.setMethodCallHandler((call) {
      print('platform channel method call ${call.method} ${call.arguments}');
      if (call.method==METHOD_PLAYASSET){
        setState(() {
          statusText = call.arguments;
        });
        if (!call.arguments.toString().contains("...")){
          prefs.setString(Preferences().asset_directory, call.arguments);
          Modular.to.pushReplacementNamed("/imageeditor");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return showLoading ? Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            Padding(
              padding: const EdgeInsets.only(top:48.0),
              child: Text(statusText),
            )
          ],
        ),
      ),
    ) :  Container(
      child: InkWell(
        onTap: ((){
          setState(() {
            showLoading = true;
          });

          print('process to loading page');
          checkIfImageEditorAssetPackExist();
          // Modular.to.pushNamed('/download').then((value) => setState((){
          //   showLoading = false;
          // }));
        }),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.edit),
              iconSize: 32,
            ),
            Container(
              alignment: Alignment.center,
              child: Text(
                'Click to try module image editor',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SharedPreferences prefs;

  Future<void> checkIfImageEditorAssetPackExist() async {
    try {
      setState(() {
        statusText = "Get asset directory";
      });
      await platform.invokeMethod<String>('get_asset', 'editorassetpack');
    } catch (_){
      setState(() {
        statusText = "Error $_";
      });
    }
  }
}

class StateLandingPage extends State<LandingPage> {
  int _currentIndex = 0;

  var _selectedWidget = [
    Container(
        child: Center(child: Text('This is Landing Page'))),
    SecondTab()
  ];

  void _onItemTapped(int index){
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modular App'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            title: Text("Main"),
            icon: Icon(Icons.home)
          ),
          BottomNavigationBarItem(
              title: Text("Edit it"),
              icon: Icon(Icons.edit)
          )
        ],
        onTap: _onItemTapped,
        currentIndex: _currentIndex,
      ),
      body: _selectedWidget[_currentIndex],
    );
  }
}
