import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pokedex/ui/Card.dart';
import 'package:pokedex/ui/GridList.dart';
import 'package:pokedex/ui/Home.dart';

class HomePage extends StatefulWidget {
  static bool _darkMode = false;
  static get darkMode => _darkMode;
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: Text("Pokedex"),
          centerTitle: true,
          actions: [
            IconButton(
                icon: Icon(
                  Icons.brightness_2,
                  color: HomePage._darkMode ? Colors.amber : Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    HomePage._darkMode = !HomePage._darkMode;
                    Home.changeTheme(HomePage._darkMode
                        ? Brightness.dark
                        : Brightness.light);
                  });
                }),
          ],
        ),
        body: GridList(),
        backgroundColor:
            HomePage._darkMode ? Colors.grey[850] : Colors.blueGrey[50]);
  }
}
