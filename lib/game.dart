import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  ); // To turn off landscape mode
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
              BoardTiles(boardSize: boardSize, padding: padding, margin: margin)
            ],
          ),
        ),
      ),
    );
  }
}

class BoardTiles extends StatefulWidget {
  const BoardTiles(
      {Key? key,
      required this.boardSize,
      required this.padding,
      required this.margin})
      : super(key: key);

  final double boardSize;
  final double padding;
  final double margin;

  @override
  _BoardTilesState createState() => _BoardTilesState();
}

class _BoardTilesState extends State<BoardTiles> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) {
            if (details.delta.dx > 0) {
              print("rechts");
            }
            if (details.delta.dx < 0) {
              print("links");
            }
            if (details.delta.dy < 0) {
              print("hoch");
            }
            if (details.delta.dy > 0) {
              print("runter");
            }
          },
        );
      },
    );
  }
}
