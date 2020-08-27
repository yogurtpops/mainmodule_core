import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';

class LandingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateLandingPage();
  }
}

class SecondTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class StateLandingPage extends State<LandingPage> {
  int _currentIndex = 0;
  var _selectedWidget = [
    Text('This is Landing Page'),
    Container(
      child: InkWell(
        onTap: ((){
          Modular.to.pushNamed('/imageeditor');
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
    )
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
