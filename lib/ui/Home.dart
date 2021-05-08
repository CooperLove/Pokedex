import 'package:flutter/material.dart';
import 'package:pokedex/HomePage.dart';
import 'package:pokedex/LauchPage.dart';

class Home extends StatefulWidget {
  static _HomeState _state;
  static Home instance = Home();
  static Brightness _brightness = Brightness.light;
  static get brightness => _brightness;
  static changeTheme(Brightness brightness) {
    _brightness = brightness;
    _state._changeTheme();
  }

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool load = false;
  @override
  void initState() {
    super.initState();
    Home._state = this;
  }

  void _changeTheme() {
    setState(() {});
    load = true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      theme: ThemeData(brightness: Home._brightness),
      darkTheme: ThemeData(brightness: Home._brightness),
      // themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
    );
  }
}
