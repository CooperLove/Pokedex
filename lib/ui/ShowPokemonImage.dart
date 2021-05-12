import 'package:flutter/material.dart';
import 'package:pokedex/Pokemon/PokemonInfo.dart';

class PokemonImage extends StatefulWidget {
  PokemonImage(this._pokemon);
  final Pokemon _pokemon;

  @override
  _PokemonImageState createState() => _PokemonImageState();
}

class _PokemonImageState extends State<PokemonImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: GestureDetector(
          child: Hero(
            tag: widget._pokemon.name,
            child: Image.network(
              widget._pokemon.spriteUrl,
              fit: BoxFit.fill,
              width: 500,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ));
  }
}
