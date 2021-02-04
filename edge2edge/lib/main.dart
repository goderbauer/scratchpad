import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {},
        ),
        extendBody: true,
        appBar: AppBar(title: const Text('The title')),
        body: ListView.builder(itemBuilder: (BuildContext context, int index) {
          return Container(
            color: index % 2 == 0 ? Colors.black : Colors.white,
            height: 100,
          );
        }),
      ),
    );
  }
}
