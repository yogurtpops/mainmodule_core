import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:fluttermodular/expansion_pack_util/expansion_helper.dart';

final String IMAGE_MODULE_EDITOR_EXPANSION_PACK_ACCESS_CODE = "/storage/emulated/0/Android/obb/com.dididi.basictomodular/main.0300110.com.dididi.basictomodular.obb";

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

  @override
  Widget build(BuildContext context) {
    return showLoading ? Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    ) :  Container(
      child: InkWell(
        onTap: ((){
          setState(() {
            showLoading = true;
          });
          checkIfImageEditorModuleFileExist();
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

  checkIfImageEditorModuleFileExist() async {
    bool packExist = await checkIfPackIsDownloaded(IMAGE_MODULE_EDITOR_EXPANSION_PACK_ACCESS_CODE);
    if (packExist){
      Modular.to.pushNamed('/imageeditor').then((value) => setState((){
        showLoading = false;
      }));
      print('pack is downloaded');
    } else {
      downloadPack(IMAGE_MODULE_EDITOR_EXPANSION_PACK_ACCESS_CODE);
      print('pack not yet downloaded');
      setState(() {
        showLoading = false;
      });
    }
  }
  
}

class StateLandingPage extends State<LandingPage> {
  int _currentIndex = 0;

  var _selectedWidget = [
    Text('This is Landing Page'),
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
