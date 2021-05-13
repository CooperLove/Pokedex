// import 'dart:html';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex/ui/Card.dart';
import 'dart:convert';
import 'dart:async';
import 'package:pokedex/ui/GridList.dart';
import 'package:html/parser.dart';

class Pokemon {
  Pokemon();
  int index;
  Image sprite;
  String spriteUrl;
  String name;
  String type1;
  String type2;
  String weight;
  String height;
  String gender;
  // List abilities;
  String baseExp;
  String ability;
  List<Pokemon> evolution_chain;
  List<String> good_against;
  List<String> weak_against;

  static Future<Pokemon> getPokemon(int index) async {
    Pokemon p = GridList.instance.getPokemon(index);
    if (p != null) return p;
    http.Response response;

    response = await http.get("https://pokeapi.co/api/v2/pokemon/$index");
    if (response.statusCode != 200) return null;

    Map pokemonData = json.decode(response.body);

    return await _createPokemon(pokemonData);
  }

  static Future<Pokemon> getPokemonByName(String name) async {
    http.Response response;
    name = name.toLowerCase();

    response = await http.get("https://pokeapi.co/api/v2/pokemon/$name");
    if (response.statusCode != 200) return null;

    Map pokemonData = json.decode(response.body);
    // print(pokemonData["types"][0]);

    return await _createPokemon(pokemonData);
  }

  static Future<Pokemon> _createPokemon(Map pokemonData) async {
    Pokemon pokemon = new Pokemon();
    pokemon.index = pokemonData["id"];
    pokemon.name = pokemonData["species"]["name"];
    print("Criando ${pokemon.name}");
    pokemon.spriteUrl = await getImage(pokemon.index, pokemon.name) ??
        pokemonData["sprites"]["front_shiny"];
    pokemon.sprite = Image.network(
      pokemon.spriteUrl ?? "",
      width: 130,
      height: 130,
      fit: BoxFit.fill,
    );
    pokemon.type1 = pokemonData["types"][0]["type"]["name"];
    List types = pokemonData["types"];
    if (types.length > 1)
      pokemon.type2 = pokemonData["types"][1]["type"]["name"];

    pokemon.height = pokemonData["height"].toString();
    pokemon.weight = pokemonData["weight"].toString();
    pokemon.baseExp = pokemonData["base_experience"].toString();
    pokemon.ability = pokemonData["abilities"][0]["ability"]["name"];
    return pokemon;
  }

  Future getEvolutionChain() async {
    print("Getting evolutions of $name => $evolution_chain");
    if (evolution_chain != null) return;
    Map evoChain = await _getEvoChainData(index);
    // if (!_evolutionExist(evoChain)) return;
    evolution_chain = [];

    int baseIndex = _getEvolutionIndex(evoChain["chain"]);
    evolution_chain
        .add(await _loadPokemonFromChain(baseIndex, evoChain["chain"]));

    if (!_evolutionExist(evoChain)) {
      _setChainToEvolutions();
      return;
    }
    List evolvesTo = evoChain["chain"]["evolves_to"];
    for (var i = 0; i < evolvesTo.length; i++) {
      int firstIndex = _getEvolutionIndex(evoChain["chain"]["evolves_to"][i]);
      evolution_chain.add(await _loadPokemonFromChain(
          firstIndex, evoChain["chain"]["evolves_to"][i]));
    }

    if (!_secondEvolutionExist(evoChain)) {
      _setChainToEvolutions();
      return;
    }
    int secondIndex = _getEvolutionIndex(evoChain["chain"]["evolves_to"][0],
        isSecondEvolution: true);
    evolution_chain.add(await _loadPokemonFromChain(
        secondIndex, evoChain["chain"]["evolves_to"][0]));

    _setChainToEvolutions();
    print(evolution_chain);
  }

  Future<Pokemon> _loadPokemonFromChain(int index, Map chain) async {
    Pokemon p = GridList.instance.getPokemon(index);
    if (p == null) {
      p = await Pokemon.getPokemon(index);
    }
    // print("$index já está carregado");

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
    if (evolution_chain != null) return null;
    http.Response response;
    //Url that contains the evo chain url
    String evoRequest = "https://pokeapi.co/api/v2/pokemon-species/$index";
    // print("Waiting $evoRequest");
    response = await http.get(evoRequest);
    Map data = json.decode(response.body);
    String evoUrl = data["evolution_chain"]["url"];
    //Get the evo chain
    // print("Waiting $evoUrl");
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
    // print("Index = $firstEvoIndex");
    return firstEvoIndex;
  }

  Future getTypeDamageRelation() async {
    if (good_against != null) return;
    http.Response response;
    //Url that contains the evo chain url
    String relationRequest = "https://pokeapi.co/api/v2/type/$type1";
    // print("Waiting $relationRequest");
    response = await http.get(relationRequest);
    Map data = json.decode(response.body);
    // print(data["damage_relations"]["double_damage_to"]);
    // print(data["damage_relations"]["half_damage_to"]);

    good_against = [];
    weak_against = [];

    List doubleDamage = data["damage_relations"]["double_damage_to"];
    for (var i = 0; i < doubleDamage.length; i++) {
      good_against.add(data["damage_relations"]["double_damage_to"][i]["name"]);
    }
    List halfDamage = data["damage_relations"]["half_damage_to"];
    for (var i = 0; i < halfDamage.length; i++) {
      weak_against.add(data["damage_relations"]["half_damage_to"][i]["name"]);
    }
  }

  void _setChainToEvolutions() {
    for (var poke in evolution_chain) {
      if (poke.index != index) poke.evolution_chain = evolution_chain;
    }
  }

  static Future<List> getPokemonsByType(String type) async {
    http.Response response;

    String url = "https://pokeapi.co/api/v2/type/$type";

    response = await http.get(url);
    Map data = json.decode(response.body);
    print("Type $type \n ${data["pokemon"]}");
    List list = data["pokemon"];
    List pokemonIndexes = [];
    for (var i = 0; i < list.length; i++) {
      String url = data["pokemon"][i]["pokemon"]["url"];
      List<String> split = url.split("/");
      // print(split);
      pokemonIndexes.add(int.tryParse(split[split.length - 2]) - 1);
    }
    return pokemonIndexes;
  }

  static Future<String> getImage(int index, String name) async {
    http.Response response;
    String url =
        "https://bulbapedia.bulbagarden.net/wiki/File:${PokemonCard.formatIndex(index).substring(1)}${PokemonCard.capitalize(name)}.png";

    // print("URL: $url");
    response = await http.get(url);
    // print("StatusCode: ${response.statusCode}");
    if (response.statusCode != 200) return null;
    var document = parse(response.body);
    var elements = document.getElementsByTagName("meta");
    // print("${elements[3].attributes["content"]}");
    return elements[3].attributes["content"];
  }

  @override
  String toString() {
    return "Pokemon {ID: $index, Name: $name}";
  }
}
