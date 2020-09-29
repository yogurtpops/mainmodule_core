// app_module.dart
import 'package:editormodule/imageeditormodule/image_editor_module.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:fluttermodular/expansion_pack_util/expansion_helper.dart';
import 'package:fluttermodular/main.dart';
import 'package:fluttermodular/mainmodule/view/landing_page.dart';

class AppModule extends MainModule {

  // Provide a list of dependencies to inject into your project
  @override
  List<Bind> get binds => [];

  // Provide all the routes for your module
  @override
  List<Router> get routers => [
    Router('/', child: (_, __) => LandingPage()),
    Router('/imageeditor', module: ImageEditorModule()),
    Router('/download', child: (_, __) => ExpansionDownloadPage()),
  ];

  // Provide the root widget associated with your module
  // In this case, it's the widget you created in the first step
  @override
  Widget get bootstrap => AppWidget();
}