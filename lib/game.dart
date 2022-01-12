import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tile.dart';
import "dart:math";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  ); // Turns off landscape mode
  runApp(const App2048());
}

class App2048 extends StatelessWidget {
  const App2048({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Board(title: "2048"),
    );
  }
}

class Board extends StatelessWidget {
  Board({Key? key, required this.title}) : super(key: key);
  final String title;
  final double padding = 7;
  final double margin = 14;
  final double maxSize = 700;
  double boardSize = 0;

  @override
  Widget build(BuildContext context) {
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);
    boardSize = queryData.size.width > maxSize ? maxSize : queryData.size.width;
    print(boardSize);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Container(
          width: boardSize - margin,
          height: boardSize - margin,
          child: Stack(
            children: <Widget>[
              Container(
                color: const Color(0xffbbada0),
                child: GridView.count(
                  padding: EdgeInsets.all(padding),
                  shrinkWrap: true,
                  primary: false,
                  crossAxisSpacing: padding,
                  mainAxisSpacing: padding,
                  crossAxisCount: 4,
                  children: <Widget>[
                    for (var i = 0; i < 16; i++)
                      Container(
                        color: const Color(0xffcdc1b4),
                      ),
                  ],
                ),
              ),
              BoardManager(
                  boardSize: boardSize, padding: padding, margin: margin)
            ],
          ),
        ),
      ),
    );
  }
}

class BoardManager extends StatefulWidget {
  BoardManager(
      {Key? key,
      required this.boardSize,
      required this.padding,
      required this.margin})
      : super(key: key) {
    tileSize = ((boardSize - margin) - padding * 5) / 4;
  }
  late final double tileSize;
  final double boardSize;
  final double padding;
  final double margin;
  final int animationDuration = 400;

  List<Tile> tiles = [];
  // Contains indexes of the tiles list.
  List<int> boardState = List.filled(16, -1, growable: false);

  @override
  _BoardManagerState createState() => _BoardManagerState();
}

class _BoardManagerState extends State<BoardManager> {
  final double _swipeSensitivity = 2;
  bool _isAnimationOngoing = false;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Stack(
        children: widget.tiles,
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanUpdate: (details) {
              if (details.delta.dx.abs() > _swipeSensitivity) {
                handleSwipe(details.delta.dx, null);
              } else if (details.delta.dy.abs() > _swipeSensitivity) {
                handleSwipe(null, details.delta.dy);
              }
            },
          );
        },
      ),
    ]);
  }

  Future<void> handleSwipe(double? xMovement, double? yMovement) async {
    if (!_isAnimationOngoing) {
      _isAnimationOngoing = true;
      //  0  1  2  3
      //  4  5  6  7
      //  8  9  10 11
      //  12 13 14 15
      if (xMovement != null) {
        //swiping horizontally
        if (xMovement > 0) {
          // swiping right
          for (int i = 0; i < 16; i += 4) {
            bool didCombine = false;
            for (int j = 2; j >= 0; j--) {
              for (int k = 1; k + j < 4; k++) {
                if (_isGridPositionEmpty(i + j)) {
                  continue;
                }
                if (widget.boardState[i + j + k] != -1) {
                  if (_areTileNumbersEqual(i + j, i + j + k) && !didCombine) {
                    _mergeTiles(i + j, i + j + k);
                    didCombine = true;
                  } else {
                    if (k > 1) {
                      _moveTile(i + j, i + j + k - 1);
                      break;
                    }
                  }
                  k = 4;
                } else if (j + k == 3) {
                  _moveTile(i + j, i + j + k);
                }
              }
            }
          }
        } else {
          //swiping left
        }
      } else {
        //swiping vertically
      }

      await Future.delayed(Duration(milliseconds: widget.animationDuration),
          () {
        //Todo only create tile if a tile moved!
        _createTile();
        _isAnimationOngoing = false;
      });
    }
  }

  void _createTile() {
    setState(() {
      var key = GlobalKey<TileState>();
      int gridNumber = _getRandomEmptyTile();
      if (gridNumber == -1) {
        AlertDialog alert = AlertDialog(
          title: Text("Game over"),
          content: Text("You lost :("),
        );

        // show the dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
        );
      } else {
        var xyPos = _calculateBoardPositionFromGridNumber(gridNumber);
        int tileNumber = 2 + Random().nextInt(2) * 2;
        widget.tiles.add(Tile(
          key: key,
          globalKey: key,
          xPos: xyPos[0],
          yPos: xyPos[1],
          number: tileNumber,
          tileSize: widget.tileSize,
        ));
        widget.boardState[gridNumber] = widget.tiles.length - 1;

        print("added Tile, tilesize: ${widget.tileSize}");
      }
    });
  }

  void _moveTile(int curGridNumber, int newGridNumber) {
    var xyPos = _calculateBoardPositionFromGridNumber(newGridNumber);
    int idx = widget.boardState[curGridNumber];
    widget.tiles[idx].globalKey.currentState
        ?.animateToPosition(xyPos[0], xyPos[1]);
    widget.boardState[newGridNumber] = widget.boardState[curGridNumber];
    widget.boardState[curGridNumber] = -1;
  }

  void _deleteTile(int tileIdx) {
    // widget.tiles[idx].globalKey.currentState?.deleteTileDelayed();
    widget.tiles.removeAt(tileIdx);

    // Update indexes of boardState
    for (int i = 0; i < 16; i++) {
      if (widget.boardState[i] > tileIdx) {
        widget.boardState[i] -= 1;
      }
    }
  }

  Future<void> _mergeTiles(int movingTile, int newGridNumber) async {
    int tileToDeleteIdx = widget.boardState[newGridNumber];
    _moveTile(movingTile, newGridNumber);
    await Future.delayed(Duration(milliseconds: widget.animationDuration));
    _deleteTile(tileToDeleteIdx);
    int idx = widget.boardState[newGridNumber];
    widget.tiles[idx].globalKey.currentState?.upgradeTile();
  }

  List<double> _calculateBoardPositionFromGridNumber(int gridNumber) {
    var xTileIdx = gridNumber % 4;
    var yTileIdx = gridNumber ~/ 4;
    double xPos =
        widget.padding + (widget.tileSize + widget.padding) * xTileIdx;
    double yPos =
        widget.padding + (widget.tileSize + widget.padding) * yTileIdx;
    return [xPos, yPos];
  }

  int _getRandomEmptyTile() {
    List<int> list = [];
    for (int i = 0; i < widget.boardState.length; i++) {
      if (widget.boardState[i] == -1) {
        list.add(i);
      }
    }
    if (list.isEmpty) {
      return -1;
    }
    return list[Random().nextInt(list.length)];
  }

  bool _areTileNumbersEqual(int gridNumber1, int gridNumber2) {
    return widget.tiles[widget.boardState[gridNumber1]].number ==
        widget.tiles[widget.boardState[gridNumber2]].number;
  }

  bool _isGridPositionEmpty(int gridNumber) {
    return widget.boardState[gridNumber] == -1;
  }
}
