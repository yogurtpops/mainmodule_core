import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:fluttermodular/expansion_pack_util/expansion_helper.dart';

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

          print('process to loading page');
          Modular.to.pushNamed('/download').then((value) => setState((){
            showLoading = false;
          }));        }),
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
    bool downloadPackExist = await checkIfPackIsDownloaded(DOWNLOADED_IMAGE_MODULE_EDITOR_EXPANSION_PACK_ACCESS_CODE);
     if (downloadPackExist){
       print('pack is downloaded');
       Modular.to.pushNamed('/imageeditor').then((value) => setState((){
         showLoading = false;
       }));

       bool extractedPackExist = await checkIfPackIsDownloaded(IMAGE_MODULE_EDITOR_EXPANSION_PACK_ACCESS_CODE);
       if (extractedPackExist){
         print('pack is extracted');
         Modular.to.pushNamed('/imageeditor').then((value) => setState((){
           showLoading = false;
         }));
       } else {
         print('pack not yet downloaded');
         Modular.to.pushNamed('/download').then((value) => setState((){
           showLoading = false;
         }));
       }

     } else {
      print('pack not yet downloaded');
      Modular.to.pushNamed('/download').then((value) => setState((){
        showLoading = false;
      }));
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
