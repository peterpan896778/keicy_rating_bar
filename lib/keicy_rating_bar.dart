library keicy_rating_bar;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef void RatingChangeCallback(double rating);

class KeicyRatingBar extends StatefulWidget {
  final int starCount;
  final double rating;
  final RatingChangeCallback onRated;
  final bool allowHalfRating;
  final double size;
  final Color starColor;
  Widget filledIconData;
  Widget halfFilledIconData;
  Widget defaultIconData; //this is needed only when having fullRatedIconData && halfRatedIconData
  final double spacing;
  final bool isReadOnly;
  final String topLabel;
  final double topLabelFontSize;
  final Color topLabelColor;
  final double topLabelSpacing;
  final String bottomLabel;
  final double bottomLabelFontSize;
  final Color bottomLabelColor;
  final double bottomLabelSpacing;

  KeicyRatingBar({
    this.starCount = 5,
    this.isReadOnly = false,
    this.spacing = 0.0,
    this.rating = 0.0,
    this.onRated,
    this.size = 25,
    this.starColor,
    defaultIconData,
    filledIconData,
    halfFilledIconData,
    this.allowHalfRating = true,
    this.topLabel = "",
    this.topLabelFontSize = 30,
    this.topLabelColor = Colors.black,
    this.topLabelSpacing = 10,
    this.bottomLabel = "",
    this.bottomLabelFontSize = 30,
    this.bottomLabelColor = Colors.black,
    this.bottomLabelSpacing = 10,
  }) {
    assert(this.rating != null);
    if (defaultIconData != null)
      this.defaultIconData = defaultIconData;
    else
      this.defaultIconData = Icon(
        Icons.star_border,
        size: this.size,
        color: this.starColor ?? Colors.green,
      );

    if (filledIconData != null)
      this.filledIconData = filledIconData;
    else
      this.filledIconData = Icon(
        Icons.star,
        size: this.size,
        color: this.starColor ?? Colors.green,
      );

    if (halfFilledIconData != null)
      this.halfFilledIconData = halfFilledIconData;
    else
      this.halfFilledIconData = Icon(
        Icons.star_half,
        color: this.starColor ?? Colors.green,
        size: this.size,
      );
  }
  @override
  _KeicyRatingBarState createState() => _KeicyRatingBarState();
}

class _KeicyRatingBarState extends State<KeicyRatingBar> {
  final double halfStarThreshold = 0.53; //half star value starts from this number

  //tracks for user tapping on this widget
  bool isWidgetTapped = false;
  double currentRating;
  double savedRating;
  Timer debounceTimer;
  @override
  void initState() {
    currentRating = widget.rating;
    savedRating = widget.rating;
    super.initState();
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    debounceTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        (widget.topLabel == "")
            ? SizedBox()
            : Text(widget.topLabel, style: TextStyle(fontSize: widget.topLabelFontSize, color: widget.topLabelColor)),
        (widget.topLabel == "") ? SizedBox() : SizedBox(height: widget.topLabelSpacing),
        Material(
          color: Colors.transparent,
          child: Wrap(
              alignment: WrapAlignment.start,
              spacing: widget.spacing,
              children: List.generate(widget.starCount, (index) => buildStar(context, index))),
        ),
        (widget.bottomLabel == "") ? SizedBox() : SizedBox(height: widget.bottomLabelSpacing),
        (widget.bottomLabel == "")
            ? SizedBox()
            : Text(widget.bottomLabel, style: TextStyle(fontSize: widget.bottomLabelFontSize, color: widget.bottomLabelColor)),
      ],
    );
  }

  Widget buildStar(BuildContext context, int index) {
    Widget ratingWidget;
    if (index >= currentRating) {
      ratingWidget = widget.defaultIconData;
    } else if (index > currentRating - (widget.allowHalfRating ? halfStarThreshold : 1.0) && index < currentRating) {
      ratingWidget = widget.halfFilledIconData;
    } else {
      ratingWidget = widget.filledIconData;
    }

    final Widget star = widget.isReadOnly
        ? ratingWidget
        : kIsWeb
            ? MouseRegion(
                onExit: (event) {
                  if (widget.onRated != null && !isWidgetTapped) {
                    //reset to zero only if rating is not set by user
                    setState(() {
                      currentRating = savedRating;
                    });
                  }
                },
                onEnter: (event) {
                  isWidgetTapped = false; //reset
                  setState(() {
                    currentRating = savedRating;
                  });
                },
                onHover: (event) {
                  RenderBox box = context.findRenderObject();
                  var _pos = box.globalToLocal(event.position);
                  var i = _pos.dx / widget.size;
                  var newRating = widget.allowHalfRating ? i : i.round().toDouble();
                  if (newRating > widget.starCount) {
                    newRating = widget.starCount.toDouble();
                  }
                  if (newRating < 0) {
                    newRating = 0.0;
                  }
                  setState(() {
                    currentRating = newRating;
                  });
                },
                child: GestureDetector(
                  onTapDown: (detail) {
                    isWidgetTapped = true;

                    RenderBox box = context.findRenderObject();
                    var _pos = box.globalToLocal(detail.globalPosition);
                    var i = ((_pos.dx - widget.spacing) / widget.size);
                    var newRating = widget.allowHalfRating ? i : i.round().toDouble();
                    if (newRating > widget.starCount) {
                      newRating = widget.starCount.toDouble();
                    }
                    if (newRating < 0) {
                      newRating = 0.0;
                    }
                    setState(() {
                      currentRating = newRating;
                      savedRating = newRating;
                    });
                    if (widget.onRated != null) {
                      widget.onRated(normalizeRating(currentRating));
                    }
                  },
                  onHorizontalDragUpdate: (dragDetails) {
                    isWidgetTapped = true;

                    RenderBox box = context.findRenderObject();
                    var _pos = box.globalToLocal(dragDetails.globalPosition);
                    var i = _pos.dx / widget.size;
                    var newRating = widget.allowHalfRating ? i : i.round().toDouble();
                    if (newRating > widget.starCount) {
                      newRating = widget.starCount.toDouble();
                    }
                    if (newRating < 0) {
                      newRating = 0.0;
                    }
                    setState(() {
                      currentRating = newRating;
                    });
                    debounceTimer?.cancel();
                    debounceTimer = Timer(Duration(milliseconds: 100), () {
                      if (widget.onRated != null) {
                        currentRating = normalizeRating(newRating);
                        widget.onRated(currentRating);
                      }
                    });
                  },
                  child: ratingWidget,
                ),
              )
            : GestureDetector(
                onTapDown: (detail) {
                  RenderBox box = context.findRenderObject();
                  var _pos = box.globalToLocal(detail.globalPosition);
                  var i = ((_pos.dx - widget.spacing) / widget.size);
                  var newRating = widget.allowHalfRating ? i : i.round().toDouble();
                  if (newRating > widget.starCount) {
                    newRating = widget.starCount.toDouble();
                  }
                  if (newRating < 0) {
                    newRating = 0.0;
                  }
                  newRating = normalizeRating(newRating);
                  setState(() {
                    currentRating = newRating;
                    savedRating = newRating;
                  });
                },
                onTapUp: (e) {
                  if (widget.onRated != null) widget.onRated(currentRating);
                },
                onHorizontalDragUpdate: (dragDetails) {
                  RenderBox box = context.findRenderObject();
                  var _pos = box.globalToLocal(dragDetails.globalPosition);
                  var i = _pos.dx / widget.size;
                  var newRating = widget.allowHalfRating ? i : i.round().toDouble();
                  if (newRating > widget.starCount) {
                    newRating = widget.starCount.toDouble();
                  }
                  if (newRating < 0) {
                    newRating = 0.0;
                  }
                  setState(() {
                    currentRating = newRating;
                  });
                  debounceTimer?.cancel();
                  debounceTimer = Timer(Duration(milliseconds: 100), () {
                    if (widget.onRated != null) {
                      currentRating = normalizeRating(newRating);
                      widget.onRated(currentRating);
                    }
                  });
                },
                child: ratingWidget,
              );

    return star;
  }

  double normalizeRating(double newRating) {
    var k = newRating - newRating.floor();
    if (k != 0) {
      //half stars
      if (k >= halfStarThreshold) {
        newRating = newRating.floor() + 1.0;
      } else {
        newRating = newRating.floor() + 0.5;
      }
    }
    return newRating;
  }
}
