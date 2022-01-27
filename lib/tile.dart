import 'package:flutter/material.dart';

class Tile extends StatefulWidget {
  double xPos;
  double yPos;
  int number;
  Color? backgroundColor;
  Color textColor = const Color(0xff776e65);

  final double tileSize;
  final int slideAniDur = 125;
  final int spawnAniDur = 125;
  final int upgrAniDur = 125;
  static const double textSizeSmall = 2.2;
  static const double textSizeNormal = 3;
  double textSize = textSizeNormal;

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
    4096: Colors.blue,
    8192: Colors.lightBlueAccent,
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
  double _newXPos = 0;
  double _newYPos = 0;
  double _scaleAnimationStart = 0.3;
  double _scaleAnimationEnd = 1.0;
  bool _didMerge = false;

  late final AnimationController _slideController = AnimationController(
    duration: Duration(milliseconds: widget.slideAniDur),
    vsync: this,
  );

  late final AnimationController _scaleController = AnimationController(
    duration: Duration(milliseconds: widget.spawnAniDur),
    vsync: this,
  )..forward();

  @override
  Widget build(BuildContext context) {
    // scaleAnimation is used for spawning and upgrading animation.
    var scaleAnimation = ScaleTransition(
      //
      scale: Tween(begin: _scaleAnimationStart, end: _scaleAnimationEnd)
          .animate(CurvedAnimation(
              parent: _scaleController, curve: Curves.easeInOut)),
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
                textScaleFactor: widget.textSize,
                textAlign: TextAlign.center,
              )
            ]),
        margin: const EdgeInsets.all(0),
        borderOnForeground: false,
        color: widget.backgroundColor,
      ),
    );

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
                parent: _slideController,
                curve: Curves.ease,
              )),
              child: scaleAnimation,
            ),
          ],
        );
      },
    );
  }

  /// Returns the new tile number.
  int upgradeTile() {
    setState(() {
      widget.number *= 2;
      widget.backgroundColor = widget.tileBackgroundColorMap[widget.number];
      if (widget.number == 8) {
        widget.textColor = Colors.white;
      }
      if (widget.number > 1000) {
        widget.textSize = Tile.textSizeSmall;
      }
      if (!_didMerge) {
        _didMerge = true;
        _scaleAnimationStart = 1.0;
        _scaleAnimationEnd = 1.09;
        _scaleController.duration = Duration(milliseconds: widget.upgrAniDur);
      }
      _scaleController.reset();
      _scaleController.forward();
      _scaleController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _scaleController.reverse();
        }
      });
    });
    return widget.number;
  }

  Future<void> animateToPosition(double newXPos, double newYPos) async {
    setState(() {
      _newXPos = newXPos;
      _newYPos = newYPos;
      _slideController
        ..reset()
        ..forward();
    });
    await Future.delayed(Duration(milliseconds: widget.slideAniDur));
    widget.xPos = newXPos;
    widget.yPos = newYPos;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
