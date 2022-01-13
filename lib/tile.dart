import 'package:flutter/material.dart';

class Tile extends StatefulWidget {
  double xPos;
  double yPos;
  int number;
  Color? backgroundColor;
  Color textColor = const Color(0xff776e65);

  final double tileSize;
  final int slideAniDur = 200;
  final int upgrAniDur = 75;

  final Map<int, Color> tileBackgroundColorMap = {
    2: Color(0xffeee4da),
    4: Color(0xffeee1c9),
    8: Color(0xfff2b279),
    16: Color(0xfff69664),
    32: Color(0xfff77c5f),
    64: Color(0xfff7623c),
    128: Color(0xffedd073),
    256: Color(0xffedcc62),
    512: Color(0xffedc950),
    1024: Color(0xffedc53f),
    2048: Color(0xffedc22e),
  };

  final GlobalKey<TileState> globalKey;

  Tile({
    Key? key,
    required this.globalKey,
    required this.xPos,
    required this.yPos,
    required this.number,
    required this.tileSize,
  }) : super(key: key) {
    backgroundColor = tileBackgroundColorMap[number];
  }

  void animateToPosition(double newXPos, double newYPos) {}

  @override
  TileState createState() => TileState();
}

class TileState extends State<Tile> with TickerProviderStateMixin {
  double _newXPos = 250;
  double _newYPos = 250;

  late final AnimationController _controller = AnimationController(
    duration: Duration(milliseconds: widget.slideAniDur),
    vsync: this,
  );

  late final AnimationController _upgrController = AnimationController(
    duration: Duration(milliseconds: widget.upgrAniDur),
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
              child: ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(
                      parent: _upgrController, curve: Curves.easeInOut)),
                  child: Card(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${widget.number}',
                            style: TextStyle(
                              color: widget.textColor,
                            ),
                            textScaleFactor: 3,
                            textAlign: TextAlign.center,
                          )
                        ]),
                    margin: EdgeInsets.all(0),
                    borderOnForeground: false,
                    color: widget.backgroundColor,
                  )),
            ),
          ],
        );
      },
    );
  }

  void upgradeTile() {
    setState(() {
      widget.number *= 2;
      widget.backgroundColor = widget.tileBackgroundColorMap[widget.number];
      if (widget.number == 8) {
        widget.textColor = Colors.white;
      }
      print(widget.backgroundColor);
      _upgrController.forward().then((value) => _upgrController.reverse());
    });
  }

  Future<void> animateToPosition(double newXPos, double newYPos) async {
    setState(() {
      _newXPos = newXPos;
      _newYPos = newYPos;
      _controller
        ..reset()
        ..forward();
    });
    await Future.delayed(Duration(milliseconds: widget.slideAniDur));
    widget.xPos = newXPos;
    widget.yPos = newYPos;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
