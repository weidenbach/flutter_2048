import 'package:flutter/material.dart';

class Tile extends StatefulWidget {
  double xPos;
  double yPos;
  int number;
  final double tileSize;
  final int animationDuration = 400;

  final GlobalKey<TileState> globalKey;

  Tile({
    Key? key,
    required this.globalKey,
    required this.xPos,
    required this.yPos,
    required this.number,
    required this.tileSize,
  }) : super(key: key);

  void animateToPosition(double newXPos, double newYPos) {}

  @override
  TileState createState() => TileState();
}

class TileState extends State<Tile> with SingleTickerProviderStateMixin {
  double _newXPos = 250;
  double _newYPos = 250;

  late final AnimationController _controller = AnimationController(
    duration: Duration(milliseconds: widget.animationDuration),
    vsync: this,
  );
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size biggest = constraints.biggest;
        return Stack(
          children: <Widget>[
            RelativePositionedTransition(
              size: biggest,
              rect: RectTween(
                begin: Rect.fromLTWH(
                    widget.xPos, widget.yPos, widget.tileSize, widget.tileSize),
                end: Rect.fromLTWH(
                    _newXPos, _newYPos, widget.tileSize, widget.tileSize),
              ).animate(CurvedAnimation(
                parent: _controller,
                curve: Curves.ease,
              )),
              child: Card(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.number}',
                        textScaleFactor: 3,
                        textAlign: TextAlign.center,
                      )
                    ]),
                margin: EdgeInsets.all(0),
                borderOnForeground: false,
                shadowColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void upgradeTile() {
    setState(() {
      widget.number *= 2;
      //TODO play upgrade animation
    });
  }

  void animateToPosition(double newXPos, double newYPos) {
    print("anitmatetoPostioin");
    setState(() {
      _newXPos = newXPos;
      _newYPos = newYPos;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
