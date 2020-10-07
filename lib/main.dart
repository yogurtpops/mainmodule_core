import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mainmodule/main_module.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({}); // set initial values here if desired

  await FlutterDownloader.initialize(debug: true);

  runApp(ModularApp(module: AppModule()));
}

class AppWidget extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // set your initial route
      initialRoute: "/",
      navigatorKey: Modular.navigatorKey,
      // add Modular to manage the routing system
      onGenerateRoute: Modular.generateRoute,
    );
  }
}