import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tile.dart';

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
      Stack(
        children: widget.tiles,
      )
    ]);
  }

  Future<void> handleSwipe(double? xMovement, double? yMovement) async {
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
              int curTileIndex = widget.boardState[i + j];
              if (curTileIndex == -1) {
                continue;
              }
              if (widget.boardState[i + j + k] != -1) {
                if (widget.tiles[curTileIndex].number ==
                        widget.tiles[widget.boardState[i + j + k]].number &&
                    !didCombine) {
                  //TODO:
                  var xyPos = _calculateBoardPositionFromGridNumber(i + j + k);
                  widget.tiles[curTileIndex].globalKey.currentState
                      ?.animateToPosition(xyPos[0], xyPos[1]);
                  //TODO MERGE TILES
                  didCombine = true;
                  k = 4;
                } else {
                  if (k > 1) {
                    var xyPos =
                        _calculateBoardPositionFromGridNumber(i + j + k - 1);
                    widget.tiles[curTileIndex].globalKey.currentState
                        ?.animateToPosition(xyPos[0], xyPos[1]);
                    break;
                  }
                }
              } else if (j + k == 3) {
                var xyPos = _calculateBoardPositionFromGridNumber(i + j + k);
                widget.tiles[curTileIndex].globalKey.currentState
                    ?.animateToPosition(xyPos[0], xyPos[1]);
                widget.boardState[i + j + k] = widget.boardState[curTileIndex];
                widget.boardState[curTileIndex] = -1;
              }
            }
            // If tile to right
            //    if canMerge
            //        merge;
            //        lockThatTileForThisMovement;
            //    else
            //        lookNextTile;

            // Check if tile is to the right,
            // if yes, check if can merge
            //         otherwise move to position before that tile.
            // if no, check next tile
          }
        }
      } else {
        //swiping left
      }
    } else {
      //swiping vertically
    }

    if (!_isAnimationOngoing) {
      _isAnimationOngoing = true;
      _createTile();
      await Future.delayed(const Duration(milliseconds: 800), () {
        _isAnimationOngoing = false;
      });
    }
  }

  void _createTile() {
    setState(() {
      //TODO generate random position on board.
      print("added Tile, tilesize: ${widget.tileSize}");
      var key = GlobalKey<TileState>();
      double number = 2;
      if (!widget.tiles.isEmpty) {
        number += 2;
      }
      widget.tiles.add(Tile(
        key: key,
        globalKey: key,
        xPos: 7,
        yPos: 7,
        number: number,
        tileSize: widget.tileSize,
      ));
      widget.boardState[0] = widget.tiles.length - 1;
      key = GlobalKey<TileState>();
      widget.tiles.add(Tile(
        key: key,
        globalKey: key,
        xPos: 7,
        yPos: 14 + widget.tileSize,
        number: number,
        tileSize: widget.tileSize,
      ));
      widget.boardState[4] = widget.tiles.length - 1;
      // for (var w in widget.tiles) {
      // w.globalKey.currentState?.animateToPosition(7, widget.tileSize + 14);
      // }
    });
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
}
