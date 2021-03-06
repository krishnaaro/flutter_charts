part of charts;

/// Customizes the crosshair.
class CrosshairBehavior extends ChartBehavior {
  CrosshairBehavior({
    ActivationMode activationMode,
    CrosshairLineType lineType,
    this.lineDashArray,
    this.enable = false,
    this.lineColor,
    this.lineWidth = 1,
    this.shouldAlwaysShow = false,
    double hideDelay,
  })  : activationMode = activationMode ?? ActivationMode.longPress,
        hideDelay = hideDelay ?? 0,
        lineType = lineType ?? CrosshairLineType.both {
    _isLongPressActivated = false;
  }

  /// Toggles the visibility of the crosshair.
  ///
  ///Defaults to false
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           crosshairBehavior: CrosshairBehavior(enable: true),
  ///        ));
  ///}
  ///```
  final bool enable;

  /// Width of the crosshair line.
  ///
  /// Defaults to 1
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           crosshairBehavior: CrosshairBehavior(
  ///                   enable: true, lineWidth: 5),
  ///        ));
  ///}
  ///```
  final double lineWidth;

  ///Color of the crosshair line. Color will be applied based on the brightness
  ///property of the app.
  ///
  ///Defaults to 1
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           crosshairBehavior: CrosshairBehavior(
  ///                   enable: true, lineColor: Colors.red),
  ///        ));
  ///}
  ///```
  final Color lineColor;

  /// Dashes of the crosshair line. Any number of values can be provided in the list.
  /// Odd value is considered as rendering size and even value is considered as gap.
  ///
  /// Dafaults to [0,0]
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           crosshairBehavior: CrosshairBehavior(
  ///                   enable: true, lineDashArray: [10,10]),
  ///        ));
  ///}
  ///```
  final List<double> lineDashArray;

  /// Gesture for activating the crosshair. Crosshair can be activated in tap, double tap
  /// and long press.
  ///
  /// Defaults to ActivationMode.longPress
  ///
  /// Also refer ActivationMode
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           crosshairBehavior: CrosshairBehavior(
  ///               enable: true, activationMode: ActivationMode.doubleTap),
  ///        ));
  ///}
  ///```
  final ActivationMode activationMode;

  /// Type of crosshair line. By default, both vertical and horizontal lines will be
  /// displayed. You can change this by specifying values to this property.
  ///
  /// Defaults to CrosshairLineType.both
  ///
  /// Also refer CrosshairLineType
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           crosshairBehavior: CrosshairBehavior(
  ///                 enable: true, lineType: CrosshairLineType.horizontal),
  ///        ));
  ///}
  ///```
  final CrosshairLineType lineType;

  /// Enables or disables the crosshair. By default, the crosshair will be hidden on touch.
  /// To avoid this, set this property to true.
  ///
  /// Defaults to false
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           crosshairBehavior: CrosshairBehavior(enable: true, shouldAlwaysShow: true),
  ///        ));
  ///}
  ///```
  final bool shouldAlwaysShow;

  ///Giving disapper delay for crosshair
  ///
  /// Defaults to 0
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           crosshairBehavior: CrosshairBehavior(enable: true, duration: 3000),
  ///        ));
  ///}
  ///```
  final double hideDelay;

  /// Touch position
  Offset _position;

  /// Holds the instance of CrosshairPainter
  _CrosshairPainter _crosshairPainter;

  /// Check whether long press activated or not .
  bool _isLongPressActivated;

  /// Displays the crosshair at the specified x and y-positions.
  ///
  ///
  /// x & y - x and y values/pixel where the crosshair needs to be shown.
  ///
  /// coordinateUnit - specify the type of x and y values given.'pixel' or 'point' for logica pixel and chart data point respectively.
  /// Defaults to 'point'.
  void show(dynamic x, double y, [String coordinateUnit]) {
    if (coordinateUnit != 'pixel') {
      final CartesianSeries<dynamic, dynamic> series =
          _crosshairPainter.chart.series[0];
      final _ChartLocation location = _calculatePoint(
          x is DateTime ? x.microsecondsSinceEpoch : x,
          y,
          series._xAxis,
          series._yAxis,
          series._chart._requireInvertedAxis,
          series,
          series._chart._chartAxis._axisClipRect);
      x = location.x;
      y = location.y;
    }

    if (_crosshairPainter != null &&
        activationMode != ActivationMode.none &&
        x != null &&
        y != null) {
      _crosshairPainter._generateAllPoints(Offset(x.toDouble(), y));
      _crosshairPainter.canResetPath = false;
      _crosshairPainter.chart._chartState.crosshairRepaintNotifier.value++;
    }
  }

  /// Displays the crosshair at the specified point index.
  ///
  ///
  /// pointIndex - index of point at which the crosshair needs to be shown.
  void showByIndex(int pointIndex) {
    if (_validIndex(pointIndex, 0, _crosshairPainter.chart)) {
      if (_crosshairPainter != null && activationMode != ActivationMode.none) {
        final CartesianSeries<dynamic, dynamic> cSeries =
            _crosshairPainter.chart.series[0];
        _crosshairPainter._generateAllPoints(Offset(
            cSeries._dataPoints[pointIndex].markerPoint.x,
            cSeries._dataPoints[pointIndex].markerPoint.y));
        _crosshairPainter.canResetPath = false;
        _crosshairPainter.chart._chartState.crosshairRepaintNotifier.value++;
      }
    }
  }

  /// Hides the crosshair if it is displayed.
  void hide() {
    if (_crosshairPainter != null) {
      _crosshairPainter.canResetPath = false;
      ValueNotifier<int>(
          _crosshairPainter.chart._chartState.crosshairRepaintNotifier.value++);
      if (_crosshairPainter.timer != null) {
        _crosshairPainter.timer.cancel();
      }
      if (!shouldAlwaysShow) {
        final double duration = (hideDelay == 0 &&
                _crosshairPainter.chart._chartState._enableDoubleTap)
            ? 200
            : hideDelay;
        _crosshairPainter.timer =
            Timer(Duration(milliseconds: duration.toInt()), () {
          _crosshairPainter.chart._chartState.crosshairRepaintNotifier.value++;
          _crosshairPainter.canResetPath = true;
        });
      }
    }
  }

  /// Enables the crosshair on double tap.
  @override
  void onDoubleTap(double xPos, double yPos) => show(xPos, yPos, 'pixel');

  /// Enables the crosshair on long press.
  @override
  void onLongPress(double xPos, double yPos) => show(xPos, yPos, 'pixel');

  /// Enables the crosshair on touch down.
  @override
  void onTouchDown(double xPos, double yPos) => show(xPos, yPos, 'pixel');

  /// Enables the crosshair on touch move.
  @override
  void onTouchMove(double xPos, double yPos) => show(xPos, yPos, 'pixel');

  /// Enables the crosshair on touch up.
  @override
  void onTouchUp(double xPos, double yPos) => hide();

  /// Draws the crosshair.
  @override
  void onPaint(Canvas canvas) {
    if (_crosshairPainter != null) {
      _crosshairPainter._drawCrosshair(canvas);
    }
  }

  void _drawLine(Canvas canvas, Paint paint, int seriesIndex) {
    if (_crosshairPainter != null) {
      _crosshairPainter._drawCrosshairLine(canvas, paint, seriesIndex);
    }
  }

  Paint _linePainter(Paint paint) => _crosshairPainter?._getLinePainter(paint);
}

class _ChartPointInfo {
  /// Marker x position
  double markerXPos;

  /// Marker y position
  double markerYPos;

  /// label for trackball and cross hair
  String label;

  /// Data point index
  int dataPointIndex;

  /// Instance of chart series
  XyDataSeries<dynamic, dynamic> series;

  /// Chart data point
  CartesianChartPoint<dynamic> chartDataPoint;

  /// X position of the label
  double xPosition;

  /// Y position of the label
  double yPosition;

  /// Color of the segment
  Color color;
}
