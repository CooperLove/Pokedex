import 'package:flutter/material.dart';
import 'package:pokedex/HomePage.dart';

class LaunchPage extends StatefulWidget {
  @override
  _LaunchPageState createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        // mainAxisAlignment: MainAxisAlignment.center,
        // crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
              child: Image.asset(
            "images/Pokeball.png",
            height: 200,
          )),
          Align(
            alignment: Alignment.bottomCenter,
            child: LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
              backgroundColor: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}
