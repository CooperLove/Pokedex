import 'package:flutter/material.dart';
import 'package:pokedex/Pokemon/PokemonInfo.dart';
import 'package:pokedex/Pokemon/TypeColors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pokedex/ui/AdvancedPokemonInfo.dart';
import 'package:pokedex/ui/GridList.dart';

class PokemonCard extends StatefulWidget {
  PokemonCard(this._pokemon);
  // final int _index;
  final Pokemon _pokemon;
  static String capitalize(String text) {
    return "${text[0].toUpperCase()}${text.substring(1)}";
  }

  static String formatIndex(int index) {
    if (index < 10) return "#00$index";
    if (index < 100) return "#0$index";
    return "#$index";
  }

  @override
  _PokemonCardState createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard> {
  @override
  Widget build(BuildContext context) {
    return _pokemonCard(context);
  }

  Widget _pokemonCard(BuildContext context) {
    return Container(
      child: Card(
        elevation: 5.0,
        borderOnForeground: true,
        color: TypeColors.typeColors[widget._pokemon.type1],
        child: GestureDetector(
          onTap: () async {
            BuildContext currentContext = context;
            Navigator.of(currentContext).push(MaterialPageRoute(
                builder: (currentContext) =>
                    AdvancedPokemonInfo(widget._pokemon)));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Stack(
                alignment: Alignment.topRight,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topCenter,
                    child: Image.network(
                      widget._pokemon.spriteUrl,
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                  Container(
                    height: 20,
                    width: 40,
                    alignment: Alignment.center,
                    // color: Colors.black54,
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius:
                            BorderRadius.only(bottomLeft: Radius.circular(10))),
                    child: Text(
                      PokemonCard.formatIndex(widget._pokemon.index),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      height: 20,
                      width: 40,
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.favorite_border),
                        color: Colors.red,
                      ),
                    ),
                  )
                ],
              ),
              Align(
                alignment: Alignment.center,
                child: Text(widget._pokemon == null
                    ? ""
                    : PokemonCard.capitalize(widget._pokemon.name)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.all(3.0),
                      child: ElevatedButton(
                        onPressed: null,
                        onLongPress: () {
                          print("type 01 pressed");
                        },
                        child:
                            Text(PokemonCard.capitalize(widget._pokemon.type1)),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              TypeColors.typeColors[widget._pokemon.type1]),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.0),
                                      side: BorderSide(color: Colors.black38))),
                        ),
                      )),
                  widget._pokemon.type2 != null
                      ? Padding(
                          padding: EdgeInsets.all(3.0),
                          child: ElevatedButton(
                            onPressed: null,
                            onLongPress: () {
                              print("type 02 pressed");
                            },
                            child: Text(
                                PokemonCard.capitalize(widget._pokemon.type2)),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  TypeColors.typeColors[widget._pokemon.type2]),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.0),
                                      side: BorderSide(color: Colors.black38))),
                            ),
                          ),
                        )
                      : Container(),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future _getEvolutionChain(int index) async {
    if (widget._pokemon.evolution_chain != null) return;
    Map evoChain = await _getEvoChainData(index);
    if (!_evolutionExist(evoChain)) return;
    widget._pokemon.evolution_chain = [];

    int baseIndex = _getEvolutionIndex(evoChain["chain"]);
    widget._pokemon.evolution_chain
        .add(await _loadPokemonFromChain(baseIndex, evoChain["chain"]));

    if (!_evolutionExist(evoChain)) return;
    int firstIndex = _getEvolutionIndex(evoChain["chain"]["evolves_to"][0]);
    widget._pokemon.evolution_chain.add(await _loadPokemonFromChain(
        firstIndex, evoChain["chain"]["evolves_to"][0]));

    if (!_secondEvolutionExist(evoChain)) return;
    int secondIndex = _getEvolutionIndex(evoChain["chain"]["evolves_to"][0],
        isSecondEvolution: true);
    widget._pokemon.evolution_chain.add(await _loadPokemonFromChain(
        secondIndex, evoChain["chain"]["evolves_to"][0]));

    print(widget._pokemon.evolution_chain);
  }

  Future<Pokemon> _loadPokemonFromChain(int index, Map chain) async {
    Pokemon p = GridList.instance.getPokemon(index);
    if (p == null) {
      p = await Pokemon.getPokemon(index);
    } else
      print("$index já está carregado");

    return p;
  }

  bool _evolutionExist(Map evoChain) {
    List firstEvo = evoChain["chain"]["evolves_to"];
    return firstEvo.length > 0;
  }

  bool _secondEvolutionExist(Map evoChain) {
    List secondEvo = evoChain["chain"]["evolves_to"][0]["evolves_to"];
    return secondEvo.length > 0;
  }

  Future<Map> _getEvoChainData(int index) async {
    http.Response response;
    //Url that contains the evo chain url
    String evoRequest = "https://pokeapi.co/api/v2/pokemon-species/$index";
    print("Waiting $evoRequest");
    response = await http.get(evoRequest);
    Map data = json.decode(response.body);
    String evoUrl = data["evolution_chain"]["url"];
    //Get the evo chain
    print("Waiting $evoUrl");
    response = await http.get(evoUrl);
    //See if there's a evolution
    return json.decode(response.body);
  }

  int _getEvolutionIndex(Map evoChain, {bool isSecondEvolution = false}) {
    String firstEvoStringIndex = !isSecondEvolution
        ? evoChain["species"]["url"]
        : evoChain["evolves_to"][0]["species"]["url"];
    List<String> split = firstEvoStringIndex.split("/");
    int firstEvoIndex = int.tryParse(split[split.length - 2]);
    print("Index = $firstEvoIndex");
    return firstEvoIndex;
  }
}
