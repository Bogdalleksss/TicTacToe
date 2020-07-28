import 'package:flutter/material.dart';
// import 'dart:html';
import 'package:socket_io_client/socket_io_client.dart' as IO;

IO.Socket socket = IO.io('http://192.168.1.16:8080', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': true
  });


void main() => runApp(App());

class App extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('TicTacToe', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),),
          elevation: 0,
          backgroundColor: Colors.purple[400],
        ),
        body: GameBoardWidget(),
      )
    );
  }
}

class GameBoardWidget extends StatefulWidget {
  @override
  _GameBoardWidget createState() => new _GameBoardWidget();
}

class _GameBoardWidget extends State<GameBoardWidget> {
  var state = {
    'r0c0' : '',
    'r0c1' : '',
    'r0c2' : '',
    'r1c0' : '',
    'r1c1' : '',
    'r1c2' : '',
    'r2c0' : '',
    'r2c1' : '',
    'r2c2' : '',
  };

  String symbol;
  String turnMsg = 'Waiting for an opponent...';
  bool myTurn = true;
  bool isActive = false;
  
  _renderTurnMessage() {
    setState(() {
      turnMsg = !myTurn ? "Your opponent's turn" : 'Your turn.';
      isActive = !myTurn ? false : true;
    });
  }

  _isGameOver() {
    var matches = ['XXX', 'OOO'];

    var rows = [
      state['r0c0'] + state['r0c1'] + state['r0c2'], // 1st line
      state['r1c0'] + state['r1c1'] + state['r1c2'], // 2nd line
      state['r2c0'] + state['r2c1'] + state['r2c2'], // 3rd line
      state['r0c0'] + state['r1c0'] + state['r2c0'], // 1st column
      state['r0c1'] + state['r1c1'] + state['r2c1'], // 2nd column
      state['r0c2'] + state['r1c2'] + state['r2c2'], // 3rd column
      state['r0c0'] + state['r1c1'] + state['r2c2'], // Primary diagonal
      state['r0c2'] + state['r1c1'] + state['r2c0']  // Secondary diagonal
    ];

    for (int i = 0; i < rows.length; i++) {
        if (rows[i] == matches[0] || rows[i] == matches[1]) {
            return true;
        }
    }

    return false;
  }

  _makeMove(id) {
    if (!myTurn) return; // Shouldn't happen since the board is disabled
    if(state[id] != '') return;  // If cell is already checked

    socket.emit("make.move", { 
        'symbol'   : symbol,
        'position' : id
    });
  }

  _socketOnMove() {
    socket.on("move.made", (data) {
      int _countNull = 0;

      // Render move
      setState(() { state[data['position']] = data['symbol']; });

      // If the symbol of the last move was the same as the current player
      // means that now is opponent's turn
      setState(() { myTurn = data['symbol'] != symbol; });

      state.forEach((key, value) { if(value == '') _countNull++; });

      if (!_isGameOver()) { // If game isn't over show who's turn is this
          _renderTurnMessage();

          if(_countNull == 0) {
            setState(() {
              turnMsg = 'You have a draw.';
              isActive = false;
            });
          }

      } else { 
          // Else show win/lose message
          setState(() { 
            turnMsg = myTurn ? 'You lost.' : 'You won!'; 
            isActive = false;
          });
      }
    });
  }

  _socketOnBegin() {
    // Bind event for game begin
    socket.on("game.begin", (data) {

        // The server is assigning the symbol
        setState(() { symbol = data['symbol']; });

        // 'X' starts first
        setState(() { myTurn = symbol == 'X'; });

        _renderTurnMessage();
    });
  }

  _socketOnLeft() {
    // Bind on event for opponent leaving the game
    socket.on("opponent.left", (_) {

        setState(() {
          turnMsg = 'Your opponent left the game.';
          isActive = false;
        });

    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidht = MediaQuery.of(context).size.width;
    String userID = socket.id == null ? '' : socket.id;

    _socketOnMove();
    _socketOnBegin();
    _socketOnLeft();

    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[

          Container(
            margin: EdgeInsets.only(top: 20),
            child: Text('Your ID: $userID'),
          ),

          Container(
            margin: EdgeInsets.only(top: 20, bottom: 60),
            width: screenWidht-36,
            height: screenWidht-36,

            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    ButtonWidget(state['r0c0'], isActive, context, 'r0c0'),
                    ButtonWidget(state['r0c1'], isActive, context, 'r0c1'),
                    ButtonWidget(state['r0c2'], isActive, context, 'r0c2'),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    ButtonWidget(state['r1c0'], isActive, context, 'r1c0'),
                    ButtonWidget(state['r1c1'], isActive, context, 'r1c1'),
                    ButtonWidget(state['r1c2'], isActive, context, 'r1c2'),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    ButtonWidget(state['r2c0'], isActive, context, 'r2c0'),
                    ButtonWidget(state['r2c1'], isActive, context, 'r2c1'),
                    ButtonWidget(state['r2c2'], isActive, context, 'r2c2'),
                  ],
                )
              ],
            )
          ),

          Text(
            '$turnMsg', 
            style: TextStyle(fontSize: 38, color: Colors.black),
            textAlign: TextAlign.center,
          ) 
        ],
      ) 
    );
  }

  Widget ButtonWidget(String sumbol, bool isActive, BuildContext context, String id) {
    double screenWidht = MediaQuery.of(context).size.width;
    
    return MaterialButton(
      minWidth: (screenWidht/3.4),
      height: (screenWidht/3.4),
      elevation: 0,
      highlightElevation: 0,
      highlightColor: isActive ? Colors.deepPurple[600] : Colors.deepPurple[200],
      color: isActive ? Colors.deepPurple[400] : Colors.deepPurple[200],
      onPressed: () {isActive ? _makeMove(id) : null;},
      child: Text('$sumbol', style: TextStyle(fontSize: 78, color: Colors.white)),
    );
  }
}