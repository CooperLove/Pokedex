import 'dart:collection';
import 'package:pokedex/Pokemon/TypeColors.dart';
import 'package:flutter/material.dart';
import 'package:pokedex/Pokemon/PokemonInfo.dart';
import 'package:pokedex/ui/AdvancedPokemonInfo.dart';
import 'package:pokedex/ui/Card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GridList extends StatefulWidget {
  static GridList instance = GridList();
  static _GridListState _state = _GridListState();
  Pokemon getPokemon(int index) {
    print("Tentando pegar pokemon $index");
    return _state.pokemons[index - 1];
  }

  static Future<Pokemon> getPokemonByIndex(int index) async =>
      await Pokemon.getPokemon(index);
  static Future<Pokemon> getPokemonByName(String name) async =>
      await Pokemon.getPokemonByName(name);

  void loadingPokemon(bool isLoading) => _state._onLoadPokemon(isLoading);

  @override
  _GridListState createState() => _GridListState();
}

class _GridListState extends State<GridList> {
  Map pokemons = Map();
  int _offset = 50;
  String _lastTypeSearched = "";
  List pokemonsByType = [];
  List _searchByTypeIndexes = [];
  int _searchByTypeOffset = -1;
  bool _searching = false;
  bool _searchFailed = false;
  bool _isLoadingPokemon = false;
  Queue<Pokemon> recentlySearched = Queue<Pokemon>();
  ScrollController gridController = ScrollController();

  void _onLoadPokemon(bool isLoading) {
    print("Mounted: ${this.mounted}");
    setState(() {
      _isLoadingPokemon = isLoading;
    });
  }

  @override
  void initState() {
    super.initState();
    GridList._state = this;
    print("State ${GridList._state}");
  }

  @override
  Widget build(BuildContext context) {
    // return _pokemonNotFound();
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 15.0),
          child: _searching
              ? (_searchFailed ? _pokemonNotFound() : _searchLayout())
              : _defaultLayout(),
        ),
        _loadingSearchedPokemon(),
      ],
    );
  }

  Widget _loadingSearchedPokemon() {
    return _isLoadingPokemon
        ? Column(
            children: [
              Expanded(
                  child: Container(
                color: Colors.black87,
                child: Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                    strokeWidth: 5.0,
                  ),
                ),
              ))
            ],
          )
        : Container();
  }

  Widget _searchLayout() {
    return Container(
      alignment: Alignment.topCenter,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          _searchField(),
          Align(
            child: Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: _circularProgressBar(),
            ),
          )
        ],
      ),
    );
  }

  Widget _defaultLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Align(
          child: _searchField(),
          alignment: Alignment.topCenter,
        ),
        _createTypeSearchListView(),
        Expanded(child: _createGrid())
      ],
    );
  }

  // Type filters
  Widget _createTypeSearchListView() {
    return Padding(
      padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.black54,
          ),
          Container(
              // color: Colors.amber,
              height: 42.5,
              width: 255,
              child: ListView(
                padding: EdgeInsets.only(right: 15),
                children: [
                  _showAllPokemonsFilter(),
                  for (String name in TypeColors.typeNames)
                    _typeButtonSearch(name)
                ],
                scrollDirection: Axis.horizontal,
              )),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.black54,
          )
        ],
      ),
    );
  }

  Widget _typeButtonSearch(String typeName) {
    return Row(
      children: [
        Container(
          height: 32.0,
          width: 80.0,
          // color: Colors.amber,
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  TypeColors.typeColors[typeName]),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      side:
                          BorderSide(color: TypeColors.typeColors[typeName]))),
            ),
            onPressed: () async {
              print("Pesquisando todos os pokemons do tipo $typeName");
              if (_lastTypeSearched == typeName)
                gridController.jumpTo(0);
              else {
                await Pokemon.getPokemonsByType(typeName).then((value) {
                  print(
                      "${value.length} pokemons do tipo $typeName encontrados");
                  _searchByTypeOffset = value.length;
                  _lastTypeSearched = typeName;
                  gridController.jumpTo(0);
                  pokemonsByType = [];
                  _searchByTypeIndexes = value;
                  setState(() {});
                });
              }
            },
            child: Text(PokemonCard.capitalize(typeName),
                style: TextStyle(fontSize: 12.5)),
          ),
        ),
        SizedBox(
          width: 6.0,
        )
      ],
    );
  }

  Widget _showAllPokemonsFilter() {
    return Row(
      children: [
        Container(
          height: 32.0,
          width: 80.0,
          // color: Colors.amber,
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all<Color>(Colors.redAccent),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      side: BorderSide(color: Colors.redAccent))),
            ),
            onPressed: () async {
              setState(() {
                _lastTypeSearched = "";
                _searchByTypeOffset = -1;
                gridController.jumpTo(0);
              });
            },
            child: Text(PokemonCard.capitalize("all"),
                style: TextStyle(fontSize: 12.5)),
          ),
        ),
        SizedBox(
          width: 6.0,
        )
      ],
    );
  }

  Widget _createGrid() {
    bool isTypeSearch = _searchByTypeOffset != -1;
    int gridOffset = isTypeSearch ? _searchByTypeOffset : _offset;
    return GridView.builder(
      controller: gridController,
      padding: EdgeInsets.all(5.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 10.0, childAspectRatio: .725),
      itemCount: gridOffset,
      itemBuilder: (context, index) {
        // print("Carregando indice $index $isTypeSearch }");
        if (index < gridOffset - (isTypeSearch ? 0 : 1)) {
          if (isTypeSearch) {
            return pokemons.length <= index && pokemonsByType.length <= index
                ? PokemonCard(pokemons[_searchByTypeIndexes[index]])
                : _getFutureCard(_searchByTypeIndexes[index]);
          }
          return (pokemons[index] == null)
              ? _getFutureCard(index, isTypeSearch: isTypeSearch)
              : PokemonCard(pokemons[index]);
        } else if (!isTypeSearch) return _loadMorePokemons();
        return Container();
      },
    );
  }

  Widget _searchField() {
    return Container(
      width: 300,
      child: TextField(
        onChanged: (text) {
          if (text.isEmpty)
            setState(() {
              _searching = false;
              _searchFailed = false;
            });
        },
        onSubmitted: (text) async {
          print("Pesquisando por $text");
          setState(() {
            _searching = true;
            _searchFailed = false;
          });
          int number = int.tryParse(text);
          Pokemon pokemon;
          if (number != null && number > 0) {
            // print("at index $number ${pokemons[number - 1]}");
            pokemon = pokemons[number - 1] ??
                recentlySearched.firstWhere((e) => e.index == number,
                    orElse: () => null) ??
                await Pokemon.getPokemon(number);
          } else
            pokemon = recentlySearched.firstWhere((e) => e.name == text,
                    orElse: () => null) ??
                await Pokemon.getPokemonByName(text);

          print("Resultado $pokemon");

          if (pokemon != null) {
            _addRecentlySearched(pokemon);
            setState(() {
              _searching = false;
              _searchFailed = false;
            });
            // await pokemon.getEvolutionChain().then((value) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AdvancedPokemonInfo(pokemon)));
            // });
          } else
            setState(() {
              _searchFailed = true;
              // _isLoadingPokemon = false;
            });
        },
        decoration: InputDecoration(
            suffixIcon: Icon(Icons.search),
            labelText: "Nome ou ID",
            hintText: "Ex: Bulbasaur ou 1",
            border: OutlineInputBorder()),
      ),
    );
  }

  Widget _getFutureCard(int index, {bool isTypeSearch = false}) {
    // print("Carregando card $index $isTypeSearch");
    return FutureBuilder(
        future: Pokemon.getPokemon(index + 1),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Card(
                borderOnForeground: true,
                elevation: 5.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(10),
                      // color: Colors.grey,
                      child: CircularProgressIndicator.adaptive(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.black45),
                        strokeWidth: 5.0,
                        value: null,
                      ),
                    )
                  ],
                ),
              );
            default:
              if (snapshot.hasError) {
                print("Error $index");
                return Container(
                  child: Card(
                    child: IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () {
                        Pokemon.getPokemon(index + 1).then((value) {
                          setState(() {});
                        });
                      },
                    ),
                  ),
                );
              }
              if (isTypeSearch)
                pokemonsByType.add(snapshot.data);
              else
                pokemons[index] = snapshot.data;
              // print("Loaded ${snapshot.data.name} => ${pokemons[index]}");
              return PokemonCard(snapshot.data);
          }
        });
  }

  Widget _loadMorePokemons() {
    return Container(
      child: GestureDetector(
        child: Card(
          elevation: 5.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.add,
                color: Colors.black,
                size: 50.0,
              ),
              Text("Carregar mais...",
                  style: TextStyle(color: Colors.black, fontSize: 15.0))
            ],
          ),
        ),
        onTap: () {
          setState(() {
            _offset += _offset;
          });
        },
      ),
    );
  }

  Widget _circularProgressBar() {
    return CircularProgressIndicator.adaptive(
      valueColor: AlwaysStoppedAnimation<Color>(Colors.black45),
      strokeWidth: 5.0,
      value: null,
    );
  }

  Widget _pokemonNotFound() {
    return Container(
      alignment: Alignment.topCenter,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          _searchField(),
          Align(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: Icon(Icons.search_off), onPressed: null),
                Text("Nenhum resultado encontrado!")
              ],
            ),
          )
        ],
      ),
    );
  }

  void _addRecentlySearched(Pokemon pokemon) {
    if (recentlySearched.length >= 20) recentlySearched.removeFirst();
    recentlySearched.add(pokemon);
  }
}
