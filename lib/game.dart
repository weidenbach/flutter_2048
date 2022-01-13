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

const int rows = 4;
const int tCnt = rows * rows; //Tiles count

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
                    for (var i = 0; i < tCnt; i++)
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
    tileSize = ((boardSize - margin) - padding * (rows + 1)) / rows;
  }
  late final double tileSize;
  final double boardSize;
  final double padding;
  final double margin;
  final int slideAniDur = 200;

  List<Tile> tiles = [];
  // Contains indexes of the tiles list.
  List<GlobalKey<TileState>?> boardState =
      List.filled(tCnt, null, growable: false);

  @override
  _BoardManagerState createState() => _BoardManagerState();
}

class _BoardManagerState extends State<BoardManager> {
  final double _swipeSensitivity = 5;
  bool _isAnimationOngoing = false;
  bool _didStart = false;

  @override
  Widget build(BuildContext context) {
    if (!_didStart) {
      _createTile();
      _createTile();
      _didStart = true;
    }
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
      List<bool> moves = [];
      if (xMovement != null) {
        //Swiping horizontally
        if (xMovement > 0) {
          // swiping right
          for (int i = 0; i < tCnt; i += rows) {
            moves.add(_moveRowOrColumn(i, i + 3, 1));
          }
        } else {
          //swiping left
          for (int i = 0; i < tCnt; i += rows) {
            moves.add(_moveRowOrColumn(i + 3, i, -1));
          }
        }
      }
      if (yMovement != null) {
        if (yMovement > 0) {
          // swiping up
          for (int i = 0; i < rows; i += 1) {
            moves.add(_moveRowOrColumn(i, i + 3 * rows, 4));
          }
        } else {
          //swiping down
          for (int i = 0; i < rows; i += 1) {
            moves.add(_moveRowOrColumn(i + 3 * rows, i, -4));
          }
        }
      }

      await Future.delayed(Duration(milliseconds: widget.slideAniDur), () {
        if (moves.contains(true)) {
          // Only create tile if a tile moved
          _createTile();
        }
        _isAnimationOngoing = false;
      });
    }
  }

  //  Grid 4 * 4:
  //  0  1  2  3
  //  4  5  6  7
  //  8  9  10 11
  //  12 13 14 15
  bool _moveRowOrColumn(int start, int end, int step) {
    bool didCombine = false;
    bool didMove = false;
    // For loops have != as condition, this way both directions can be checked,
    // with < and > only one directional check would be possible.
    for (int curTile = start + step * 2;
        curTile != start - step;
        curTile -= step) {
      if (_isGridPositionEmpty(curTile)) {
        continue;
      }
      for (int i = step; i + curTile != end + step; i += step) {
        if (!_isGridPositionEmpty(curTile + i)) {
          if (_areTileNumbersEqual(curTile, curTile + i) && !didCombine) {
            _mergeTiles(curTile, curTile + i);
            didCombine = true;
            didMove = true;
          } else {
            // Move to position before that tile, if curTile isn't already there
            if (curTile != curTile + i - step) {
              _moveTile(curTile, curTile + i - step);
              didMove = true;
            }
          }
          break; // Stop because tile was moved
        } else if (curTile + i == end) {
          _moveTile(curTile, curTile + i);
          didMove = true;
        }
      }
    }
    return didMove;
  }

  void _createTile() {
    setState(() {
      var key = GlobalKey<TileState>();
      int gridNumber = _getRandomEmptyTile();
      if (gridNumber == -1) {
        AlertDialog alert = const AlertDialog(
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
        //Todo switch back to random
        int tileNumber = 2;
        // int tileNumber = 2 + Random().nextInt(2) * 2;
        widget.tiles.add(Tile(
          key: key,
          globalKey: key,
          xPos: xyPos[0],
          yPos: xyPos[1],
          number: tileNumber,
          tileSize: widget.tileSize,
        ));
        widget.boardState[gridNumber] = key;
        print("added Tile, tilesize: ${widget.tileSize}");
      }
    });
  }

  void _moveTile(int curGridNumber, int newGridNumber) {
    var xyPos = _calculateBoardPositionFromGridNumber(newGridNumber);
    widget.boardState[curGridNumber]?.currentState
        ?.animateToPosition(xyPos[0], xyPos[1]);
    widget.boardState[newGridNumber] = widget.boardState[curGridNumber];
    widget.boardState[curGridNumber] = null;
  }

  void _deleteTile(GlobalKey<TileState>? tileKey) {
    if (tileKey == null) {
      throw Exception("Tile key was null");
    }
    for (int i = 0; i < widget.tiles.length; i++) {
      if (widget.tiles[i].globalKey == tileKey) {
        widget.tiles.removeAt(i);
      }
    }
  }

  Future<void> _mergeTiles(int movingTile, int newGridNumber) async {
    GlobalKey<TileState>? tileToDeleteKey = widget.boardState[newGridNumber];
    _moveTile(movingTile, newGridNumber);
    // Wait a bit less than the sliding animation to upgrade the tile
    await Future.delayed(
        Duration(milliseconds: (widget.slideAniDur * 0.65).toInt()));
    _deleteTile(tileToDeleteKey);
    widget.boardState[newGridNumber]?.currentState?.upgradeTile();
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
      if (widget.boardState[i] == null) {
        list.add(i);
      }
    }
    if (list.isEmpty) {
      return -1;
    }
    return list[Random().nextInt(list.length)];
  }

  bool _areTileNumbersEqual(int gridNumber1, int gridNumber2) {
    return widget.boardState[gridNumber1]?.currentState?.widget.number ==
        widget.boardState[gridNumber2]?.currentState?.widget.number;
  }

  bool _isGridPositionEmpty(int gridNumber) {
    return widget.boardState[gridNumber] == null;
  }
}
