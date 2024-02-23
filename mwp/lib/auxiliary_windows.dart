import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mwp/src/context_menu.dart';
import 'package:mwp/src/tooltip.dart';

void main() {
  runApp(
    const MaterialApp(
      home: AuxiliaryWindowApp(),
    ),
  );
}

class AuxiliaryWindowApp extends StatefulWidget {
  const AuxiliaryWindowApp({super.key});

  @override
  State<AuxiliaryWindowApp> createState() => _AuxiliaryWindowAppState();
}

class _AuxiliaryWindowAppState extends State<AuxiliaryWindowApp> {
  bool showExp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🇩🇪 Guten Tag! 🇩🇪'),
      ),
      body: WindowedContextMenu(
        entries: <Widget>[
          ListTile(
            onTap: () {},
            title: const Text('Special thanks to:'),
          ),
          const Divider(),
          ListTile(
            onTap: () {},
            leading: const FlutterLogo(),
            title: const Text('Loïc Sharma'),
          ),
          ListTile(
            onTap: () {},
            leading: const FlutterLogo(),
            title: const Text('Tong Mu'),
          ),
          ListTile(
            onTap: () {},
            leading: const FlutterLogo(),
            title: const Text('Paul Blasi'),
          ),
          ListTile(
            onTap: () {},
            leading: const FlutterLogo(),
            title: const Text('Alex Wallen'),
          ),
          const Divider(),
          ListTile(
            onTap: () {},
            leading: const Icon(
              Icons.favorite,
              color: Colors.blue,
            ),
            title: const Text('and many more!'),
          ),
          const Divider(),
          ListTile(
            onTap: () {},
            leading: const Icon(Icons.cut),
            title: const Text('Ausschneiden'),
          ),
          ListTile(
            onTap: () {},
            leading: const Icon(Icons.copy),
            title: const Text('Kopieren'),
          ),
          ListTile(
            onTap: () {},
            leading: const Icon(Icons.paste),
            title: const Text('Einfügen'),
          ),
        ],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WindowedTooltip(
                message:
                    'Rinderkennzeichnungsfleischetikettierungsüberwachungsaufgabenübertragungsgesetz',
                child: ElevatedButton(
                  onPressed: () {
                    for (Display d in PlatformDispatcher.instance.displays) {
                      print('Display: ${d.size} - ${d.devicePixelRatio}');
                    }
                    print('current: ${View.of(context).devicePixelRatio}, ${View.of(context).physicalConstraints}');
                    setState(() {
                      showExp = !showExp;
                    });
                  },
                  child: const Text('Rin...setz'),
                ),
              ),
              const SizedBox(height: 40),
              // WindowedContextMenu(
              //   entries: entries,
              //   child: Container(
              //     color: Colors.blue,
              //     height: 40,
              //     width: 150,
              //     child: const Center(child: Text('Right click me!')),
              //   ),
              // ),
              if (showExp)
                const Text(
                  'Law that governs the delegation of duties\naround supervising the labeling of beef products',
                  textAlign: TextAlign.center,
                )
            ],
          ),
        ),
      ),
    );
  }
}
