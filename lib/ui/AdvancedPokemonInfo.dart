import 'package:flutter/material.dart';
import 'package:pokedex/Pokemon/PokemonInfo.dart';
import 'package:pokedex/ui/Card.dart';
import 'package:pokedex/ui/Home.dart';
import 'package:pokedex/HomePage.dart';
import 'package:pokedex/Pokemon/TypeColors.dart';
// import 'package:flutter/gestures.dart';
// import 'package:pokedex/main.dart';
// import 'package:pokedex/ui/ShowPokemonImage.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

import 'package:pokedex/ui/GridList.dart';

class AdvancedPokemonInfo extends StatefulWidget {
  AdvancedPokemonInfo(this._pokemon);
  Pokemon _pokemon;
  @override
  _AdvancedPokemonInfoState createState() => _AdvancedPokemonInfoState();
}

class _AdvancedPokemonInfoState extends State<AdvancedPokemonInfo> {
  bool _loadedEvolutions = false;
  ScrollController scrollController = ScrollController();
  PageController controller = PageController();

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: widget._pokemon.index - 1);
    _initPokemon();
    _getTypeRelation();
  }

  Future _initPokemon() async {
    await widget._pokemon.getEvolutionChain();

    if (this.mounted) {
      setState(() {
        _loadedEvolutions = true;
      });
    }
  }

  Future _getTypeRelation() async {
    await widget._pokemon.getTypeDamageRelation();
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          GridList.instance.loadingPokemon(false);
          return true;
        },
        child: Scaffold(
          backgroundColor:
              HomePage.darkMode ? Colors.grey[850] : Colors.blueGrey[50],
          // appBar: _sliverLayout(),
          // body: _sliverLayout(),
          body: pageView(),
        ));
  }

  Widget _appBar() {
    return AppBar(
      backgroundColor: Colors.red,
      title: Text(PokemonCard.capitalize(widget._pokemon.name)),
      centerTitle: true,
    );
  }

  Widget pageView() {
    return PageView.builder(
      controller: controller,
      // itemCount: 3,
      itemBuilder: (context, index) {
        return _sliverLayout();
      },
      onPageChanged: (index) async {
        print("Está na página $index, carregando pokemon $index+1");
        widget._pokemon = await Pokemon.getPokemon(index + 1);
        setState(() {});
        _initPokemon();
        _getTypeRelation();
        setState(() {});
      },
    );
  }

  Widget _sliverLayout() {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverAppBar(
          // floating: true,
          pinned: true,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15))),
          // pinned: true,
          expandedHeight: 300,
          backgroundColor: TypeColors.typeColors[widget._pokemon.type1],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(PokemonCard.capitalize(widget._pokemon.name)),
            centerTitle: true,
            background: Container(
              child: Hero(
                tag: widget._pokemon.name,
                child: widget._pokemon.sprite ??
                    Image.network(
                      widget._pokemon.spriteUrl,
                      fit: BoxFit.fill,
                      // width: 500,
                    ),
              ),
              decoration: BoxDecoration(
                  color: TypeColors.typeColors[widget._pokemon.type1],
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15))),
            ),
          ),
          // title: Text("Pokedex"),
          // centerTitle: true,
          actions: [
            Container(
              padding: EdgeInsets.only(right: 5),
              height: 50,
              alignment: Alignment.center,
              // color: Colors.amber,
              child: Text(
                PokemonCard.formatIndex(widget._pokemon.index),
                style: TextStyle(fontSize: 18),
              ),
            )
          ],
        ),
        SliverList(delegate: SliverChildListDelegate([_normalLayout()]))
        // _normalLayout()
      ],
    );
  }

  Widget _alternateLayout() {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(top: 15.0),
        // color: Colors.amber,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 15.0, bottom: 10.0),
              child: Text(
                "Types",
                style: TextStyle(fontSize: 20),
              ),
            ),
            Container(
              width: 165,
              child: Row(
                mainAxisAlignment: widget._pokemon.type2 != null
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  _createTypeButton(widget._pokemon.type1),
                  _createTypeButton(widget._pokemon.type2),
                ],
              ),
            ),
            _typeRelationCard()
          ],
        ),
      ),
    );
  }

  Widget _normalLayout() {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _alternateLayout(),
            Padding(
                padding: EdgeInsets.only(bottom: 15, top: 15.0),
                child: Text(
                  "Stats",
                  style: TextStyle(fontSize: 20),
                )),
            _infoCard(),
            Padding(
              padding: EdgeInsets.only(bottom: 10.0, top: 15.0),
              child: Text(
                "Evolutions",
                style: TextStyle(fontSize: 20),
              ),
            ),
            _evolutionCard()
          ],
        ),
      ),
    );
  }

  Widget _circularPhoto() => Container(
        height: 200,
        margin: EdgeInsets.only(left: 75, right: 75),
        child: Card(
          shape: CircleBorder(),
          child: Image.network(
            widget._pokemon.spriteUrl,
            fit: BoxFit.fitHeight,
          ),
        ),
      );

  Widget _typeRelationCard() {
    return Padding(
      padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text("Good against"),
          ),
          _goodAgainstList() ?? Text("--"),
          Padding(
            padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
            child: Text("Weak against"),
          ),
          _weakAgainstList(),
        ],
      ),
    );
  }

  Widget _goodAgainstList() {
    return widget._pokemon.good_against != null &&
            widget._pokemon.good_against.length > 0
        ? Container(
            // color: Colors.amberAccent,
            width: 250,
            height: 35,
            child: Center(
              child: ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (context, index) {
                    return SizedBox(
                      width: 10,
                    );
                  },
                  scrollDirection: Axis.horizontal,
                  itemCount: widget._pokemon.good_against.length,
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        _createTypeButton(widget._pokemon.good_against[index]),
                      ],
                    );
                  }),
            ),
          )
        : null;
  }

  Widget _weakAgainstList() {
    return widget._pokemon.weak_against != null
        ? Container(
            // color: Colors.amberAccent,
            width: 250,
            height: 35,
            child: Center(
              child: ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (context, index) {
                    return SizedBox(
                      width: 10,
                    );
                  },
                  scrollDirection: Axis.horizontal,
                  itemCount: widget._pokemon.weak_against.length,
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        _createTypeButton(widget._pokemon.weak_against[index]),
                      ],
                    );
                  }),
            ),
          )
        : Container();
  }

  Widget _infoCard() {
    return Container(
      height: 200,
      // color: Colors.amberAccent,
      margin: EdgeInsets.only(left: 20, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Padding(
            padding: EdgeInsets.only(left: 15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _createRectangularBorder("Height"),
                _statValueText(widget._pokemon.height),
                _createRectangularBorder("Weight"),
                _statValueText(widget._pokemon.weight),
                _createRectangularBorder("Gender"),
                _pokemonGenders()
              ],
            ),
          )),
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _createRectangularBorder("Base Experience"),
              _statValueText(widget._pokemon.baseExp),
              _createRectangularBorder("Abilities"),
              _statValueText(PokemonCard.capitalize(widget._pokemon.ability)),
              Text(""),
              Container(
                margin: EdgeInsets.only(right: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 25,
                      height: 25,
                    ),
                    Container(
                      width: 25,
                      height: 25,
                    ),
                    // Image.asset("images/FemaleIcon.jpg"),
                  ],
                ),
              )
            ],
          ))
        ],
      ),
    );
  }

  Widget _evolutionCard() {
    // if (evolutions == null) _initPokemon();
    return _loadedEvolutions
        ? _loadedEvolutionCard()
        : Container(
            height: 70,
            margin: EdgeInsets.only(left: 20, right: 20),
            child: _loadingCard(),
          );
  }

  Widget _loadedEvolutionCard() {
    List evolutions = widget._pokemon.evolution_chain ?? [];
    return Container(
      height: 120.0 * evolutions.length,
      margin: EdgeInsets.only(left: 20, right: 20),
      child: Container(
        padding: EdgeInsets.only(top: 10),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            for (var i in evolutions)
              Container(
                margin: EdgeInsets.only(top: 120.0 * evolutions.indexOf(i)),
                height: 100,
                child: Center(
                  child: _evolutionCircle(i.spriteUrl, i),
                ),
              ),
            for (var i in evolutions)
              if (evolutions.indexOf(i) < evolutions.length - 1)
                _drawArrow(70.0 + (120.0 * evolutions.indexOf(i)))
          ],
        ),
      ),
    );
  }

  Widget _loadingCard() {
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
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getThemeColorCustom(Colors.black45, Colors.white54)),
              strokeWidth: 5.0,
              value: null,
            ),
          )
        ],
      ),
    );
  }

  Widget _evolutionCircle(String url, Pokemon pokemon) {
    return GestureDetector(
      onTap: () async {
        if (widget._pokemon != pokemon) {
          print("Pesquisando ${pokemon.name}");
          Pokemon p = await GridList.getPokemonByIndex(pokemon.index);
          if (p != null) {
            await p.getEvolutionChain();
            await p.getTypeDamageRelation();
            setState(() {
              widget._pokemon = p;
            });
            print(scrollController.offset);
            controller.animateToPage(pokemon.index - 1,
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
            await scrollController.animateTo(50,
                duration: Duration(milliseconds: 650), curve: Curves.easeInOut);
          }
        }
      },
      child: Container(
        // color: Colors.amber,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _circularContainer(url, _getThemeColorBlackWhite()),
            ),
            SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      PokemonCard.capitalize(pokemon.name),
                      style: TextStyle(
                          color: _getThemeColorBlackWhite(),
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 5),
                    Text(
                      PokemonCard.formatIndex(pokemon.index),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 15.0),
                  child: Row(
                    children: [
                      _createTypeButton(widget._pokemon.type1),
                      SizedBox(width: 15.0),
                      _createTypeButton(widget._pokemon.type2),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _circularContainer(String url, Color borderColor) {
    return Container(
      // margin: EdgeInsets.only(bottom: 15),
      // alignment: Alignment.center,
      height: 80,
      width: 80,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
          image: DecorationImage(image: NetworkImage(url))),
    );
  }

  Widget _createTypeButton(String type, {double size = 27.5}) {
    if (type == null) return Container();
    return Container(
      height: size,
      child: ElevatedButton(
          onPressed: () {},
          onLongPress: () {},
          child: Text(PokemonCard.capitalize(type)),
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(TypeColors.typeColors[type]),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                    side: BorderSide(color: TypeColors.typeColors[type]))),
          )),
    );
  }

  Widget _createRectangularBorder(String label,
      {Color backgroundColor = Colors.transparent}) {
    return Container(
      height: 20.0,
      width: label.replaceAll(" ", "").length * 8.5,
      child: Center(
        child: Text(label),
      ),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        border: Border.all(color: TypeColors.typeColors[widget._pokemon.type1]),
        color: backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
        // color: Colors.amberAccent
      ),
    );
  }

  Widget _statValueText(String label) {
    return Padding(
      padding: EdgeInsets.only(left: 5.0),
      child: Text(
        label ?? "",
        style: TextStyle(fontSize: 20.0, color: Colors.lightBlue),
      ),
    );
  }

  Widget _pokemonGenders() {
    return Container(
      margin: EdgeInsets.only(left: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 25,
            height: 25,
            child: Image.asset("images/MaleIcon.png"),
          ),
          Container(
            width: 25,
            height: 25,
            child: Image.asset("images/FemaleIcon.png"),
          ),
          // Image.asset("images/FemaleIcon.jpg"),
        ],
      ),
    );
  }

  Widget _drawArrow(double topMargin) {
    return Container(
      height: 30,
      margin: EdgeInsets.only(top: topMargin),
      child: IconButton(
        iconSize: 65,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: _getThemeColorBlackWhite(),
        ),
        onPressed: null,
      ),
    );
  }

  Color _getThemeColorBlackWhite() =>
      Home.brightness == Brightness.light ? Colors.black : Colors.white;
  Color _getThemeColorCustom(Color lightColor, Color darkColor) =>
      Home.brightness == Brightness.light ? lightColor : darkColor;
}
