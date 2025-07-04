import 'package:flutter/material.dart';
import 'package:tac_tics/src/rust/api/game.dart';
import 'package:tac_tics/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

Widget grid = Row(children: [Column(children: [IconButton(onPressed: () {print("object")}, icon: icon)])]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var game = UTTTGame.newInstance();
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Row(children: [Col])),
      ),
    );
  }
}
