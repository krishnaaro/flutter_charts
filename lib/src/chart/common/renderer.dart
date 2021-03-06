part of charts;

// ignore: must_be_immutable
class _DataLabelRenderer extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  _DataLabelRenderer({this.cartesianChart, this.show});

  final SfCartesianChart cartesianChart;

  bool show;

  _DataLabelRendererState state;

  @override
  State<StatefulWidget> createState() => _DataLabelRendererState();
}

class _DataLabelRendererState extends State<_DataLabelRenderer>
    with SingleTickerProviderStateMixin {
  List<AnimationController> animationControllersList;

  /// Animation controller for series
  AnimationController animationController;

  /// Repaint notifier for crosshair container
  ValueNotifier<int> dataLabelRepaintNotifier;

  @override
  void initState() {
    dataLabelRepaintNotifier = ValueNotifier<int>(0);
    animationController = AnimationController(vsync: this)
      ..addListener(repaintDataLabelElements);
    super.initState();
  }

  @override
  void dispose() {
    if (animationController != null) {
      animationController.removeListener(repaintDataLabelElements);
      animationController.dispose();
      animationController = null;
    }
    super.dispose();
  }

  void repaintDataLabelElements() {
    dataLabelRepaintNotifier.value++;
  }

  void render() {
    setState(() {
      widget.show = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    widget.state = this;
    animationController.duration = const Duration(milliseconds: 500);
    final Animation<double> dataLabelAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.1, 0.8, curve: Curves.decelerate),
    ));
    if (widget.cartesianChart._chartState.initialRender) {
      animationController.forward(from: 0.0);
    }
    return !widget.show
        ? Container()
        : Container(
            child: CustomPaint(
                painter: _DataLabelPainter(
                    cartesianChart: widget.cartesianChart,
                    animation: dataLabelAnimation,
                    state: this,
                    animationController: animationController,
                    notifier: dataLabelRepaintNotifier)));
  }
}

class _DataLabelPainter extends CustomPainter {
  _DataLabelPainter(
      {this.cartesianChart,
      this.state,
      this.animationController,
      this.animation,
      ValueNotifier<num> notifier})
      : super(repaint: notifier);

  final SfCartesianChart cartesianChart;

  final _DataLabelRendererState state;

  final AnimationController animationController;

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(cartesianChart._chartAxis._axisClipRect);
    cartesianChart._chartState.renderDatalabelRegions = <Rect>[];
    for (int i = 0; i < cartesianChart._chartSeries.visibleSeries.length; i++) {
      final XyDataSeries<dynamic, dynamic> series =
          cartesianChart._chartSeries.visibleSeries[i];
      if (series.dataLabelSettings.isVisible &&
          series.dataLabelSettings.builder == null) {
        for (dynamic Point in series._dataPoints) {
          if (series._visible && series.dataLabelSettings != null) {
            _drawDataLabel(
                canvas,
                series,
                series._chart,
                series.dataLabelSettings,
                Point,
                series._dataPoints.indexOf(Point),
                animation);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_DataLabelPainter oldDelegate) => true;
}

void _calculateSeriesRegion(SfCartesianChart chart, int index) {
  final List<Color> palette = chart.palette;
  final XyDataSeries<dynamic, dynamic> series =
      chart._chartSeries.visibleSeries[index];
  series._chart = chart;
  final int seriesIndex =
      series._chart._chartSeries.visibleSeries.indexOf(series);
  series._seriesColor = series.color ??
      palette[index % palette.length]; // sets default color for series.
  final ChartAxis xAxis = series._xAxis;
  final ChartAxis yAxis = series._yAxis;
  final Rect rect = _calculatePlotOffset(chart._chartAxis._axisClipRect,
      Offset(xAxis.plotOffset, yAxis.plotOffset));
  series._isRectSeries = (series._seriesType == 'column' ||
          series._seriesType == 'bar' ||
          series._seriesType.contains('stackedcolumn') ||
          series._seriesType.contains('stackedbar') ||
          series._seriesType == 'rangecolumn')
      ? true
      : false;
  series._regionalData = <dynamic, dynamic>{};
  CartesianChartPoint<dynamic> point;
  final num markerHeight = series.markerSettings.height,
      markerWidth = series.markerSettings.width;
  final dynamic tempSize = <dynamic>[];
  double bubbleSize;
  final bool isPointSeries =
      (series._seriesType == 'scatter' || series._seriesType == 'bubble')
          ? true
          : false;
  final bool isFastLine = (series._seriesType == 'fastline') ? true : false;

  if (series._seriesType == 'bubble') {
    for (int pointIndex = 0;
        pointIndex < series._dataPoints.length;
        pointIndex++) {
      point = series._dataPoints[pointIndex];
      if (series.sizeValueMapper == null) {
        point.bubbleSize = 4;
        bubbleSize = point.bubbleSize.toDouble();
        tempSize.add(bubbleSize.abs());
      } else {
        if (point.bubbleSize == null) {
          continue;
        } else {
          bubbleSize = point.bubbleSize.toDouble();
          tempSize.add(bubbleSize.abs());
        }
      }
    }
    tempSize.sort();
  }
  if ((!isFastLine ||
          (isFastLine &&
              (series.markerSettings.isVisible ||
                  series.dataLabelSettings.isVisible ||
                  series.enableTooltip))) &&
      series._visible) {
    for (int pointIndex = 0;
        pointIndex < series._dataPoints.length;
        pointIndex++) {
      point = series._dataPoints[pointIndex];
      if (series._isRectSeries) {
        _calculateRectSeriesRegion(point, pointIndex, series, chart);
      } else if (isPointSeries) {
        _calculatePointSeriesRegion(
            point, pointIndex, series, chart, tempSize, bubbleSize, rect);
      } else {
        _calculatePathSeriesRegion(
            point, pointIndex, series, chart, rect, markerHeight, markerWidth);
      }
      _calculateTooltipRegion(point, seriesIndex, series, chart);
    }

    /// Store the marker points before rendering
    _storeMarkerRegion(series);
  }
}

/// find rect type series region
void _calculateRectSeriesRegion(
    CartesianChartPoint<dynamic> point,
    int pointIndex,
    XyDataSeries<dynamic, dynamic> series,
    SfCartesianChart chart) {
  final ChartAxis xAxis = series._xAxis;
  final ChartAxis yAxis = series._yAxis;

  /// side by side range calculated
  final _VisibleRange sideBySideInfo = _calculateSideBySideInfo(series, chart);
  final num origin = math.max(yAxis._visibleRange.minimum, 0);

  /// Get the rectangle based on points
  final Rect rect = series._seriesType.contains('stackedcolumn') ||
          series._seriesType.contains('stackedbar')
      ? _calculateRectangle(
          point.xValue + sideBySideInfo.minimum,
          series._stackingValues[0].endValues[pointIndex],
          point.xValue + sideBySideInfo.maximum,
          series._stackingValues[0].startValues[pointIndex],
          series,
          chart)
      : _calculateRectangle(
          point.xValue + sideBySideInfo.minimum,
          series._seriesType == 'rangecolumn' ? point.high : point.yValue,
          point.xValue + sideBySideInfo.maximum,
          series._seriesType == 'rangecolumn' ? point.low : origin,
          series,
          chart);
  point.region = rect;

  ///Get shadow rect region
  if (series._seriesType != 'stackedcolumn100' &&
      series._seriesType != 'stackedbar100') {
    final Rect shadowPointRect = _calculateShadowRectangle(
        point.xValue + sideBySideInfo.minimum,
        series._seriesType == 'rangecolumn' ? point.high : point.yValue,
        point.xValue + sideBySideInfo.maximum,
        series._seriesType == 'rangecolumn' ? point.high : origin,
        series,
        chart,
        Offset(xAxis?.plotOffset, yAxis?.plotOffset));

    point.trackerRectRegion = shadowPointRect;
  }
  if (series._seriesType == 'rangecolumn') {
    point.markerPoint = chart._requireInvertedAxis != true
        ? _ChartLocation(rect.topCenter.dx, rect.topCenter.dy)
        : _ChartLocation(rect.centerRight.dx, rect.centerRight.dy);
    point.markerPoint2 = chart._requireInvertedAxis != true
        ? _ChartLocation(rect.bottomCenter.dx, rect.bottomCenter.dy)
        : _ChartLocation(rect.centerLeft.dx, rect.centerLeft.dy);
  } else {
    point.markerPoint = chart._requireInvertedAxis != true
        ? (yAxis.isInversed
            ? (point.yValue.isNegative
                ? _ChartLocation(rect.topCenter.dx, rect.topCenter.dy)
                : _ChartLocation(rect.bottomCenter.dx, rect.bottomCenter.dy))
            : (point.yValue.isNegative
                ? _ChartLocation(rect.bottomCenter.dx, rect.bottomCenter.dy)
                : _ChartLocation(rect.topCenter.dx, rect.topCenter.dy)))
        : (yAxis.isInversed
            ? (point.yValue.isNegative
                ? _ChartLocation(rect.centerRight.dx, rect.centerRight.dy)
                : _ChartLocation(rect.centerLeft.dx, rect.centerLeft.dy))
            : (point.yValue.isNegative
                ? _ChartLocation(rect.centerLeft.dx, rect.centerLeft.dy)
                : _ChartLocation(rect.centerRight.dx, rect.centerRight.dy)));
  }
}

///calculate scatter, bubble series datapoints region
void _calculatePointSeriesRegion(
    CartesianChartPoint<dynamic> point,
    int pointIndex,
    XyDataSeries<dynamic, dynamic> series,
    SfCartesianChart chart,
    dynamic tempSize,
    double bubbleSize,
    Rect rect) {
  final ChartAxis xAxis = series._xAxis;
  final ChartAxis yAxis = series._yAxis;
  final _ChartLocation currentPoint = _calculatePoint(point.xValue,
      point.yValue, xAxis, yAxis, chart._requireInvertedAxis, series, rect);
  point.markerPoint = currentPoint;
  if (series._seriesType == 'scatter') {
    point.region = Rect.fromLTRB(
        currentPoint.x - series.markerSettings.width,
        currentPoint.y - series.markerSettings.width,
        currentPoint.x + series.markerSettings.width,
        currentPoint.y + series.markerSettings.width);
  } else {
    final BubbleSeries<dynamic, dynamic> bubbleSeries = series;
    num bubbleRadius, sizeRange, radiusRange, maxSize, minSize;
    maxSize = tempSize[tempSize.length - 1];
    minSize = tempSize[0];
    sizeRange = maxSize - minSize;
    bubbleSize = ((point.bubbleSize) ?? 4).toDouble();
    if (bubbleSeries.sizeValueMapper == null)
      bubbleSeries.minimumRadius != null
          ? bubbleRadius = bubbleSeries.minimumRadius
          : bubbleRadius = bubbleSeries.maximumRadius;
    else {
      if ((bubbleSeries.maximumRadius != null) &&
          (bubbleSeries.minimumRadius != null)) {
        if (sizeRange == 0)
          bubbleRadius = bubbleSeries.maximumRadius;
        else {
          radiusRange =
              (bubbleSeries.maximumRadius - bubbleSeries.minimumRadius) * 2;
          bubbleRadius =
              (((bubbleSize.abs() - minSize) * radiusRange) / sizeRange) +
                  bubbleSeries.minimumRadius;
        }
      }
    }
    point.region = Rect.fromLTRB(
        currentPoint.x - 2 * bubbleRadius,
        currentPoint.y - 2 * bubbleRadius,
        currentPoint.x + 2 * bubbleRadius,
        currentPoint.y + 2 * bubbleRadius);
  }
}

///calculate data point region for path series like line, area, etc.,
void _calculatePathSeriesRegion(
    CartesianChartPoint<dynamic> point,
    int pointIndex,
    XyDataSeries<dynamic, dynamic> series,
    SfCartesianChart chart,
    Rect rect,
    num markerHeight,
    num markerWidth) {
  final ChartAxis xAxis = series._xAxis;
  final ChartAxis yAxis = series._yAxis;
  final _ChartLocation currentPoint = series._seriesType == 'stackedarea' ||
          series._seriesType == 'stackedarea100' ||
          series._seriesType == 'stackedline' ||
          series._seriesType == 'stackedline100'
      ? _calculatePoint(
          point.xValue,
          series._stackingValues[0].endValues[pointIndex],
          xAxis,
          yAxis,
          chart._requireInvertedAxis,
          series,
          rect)
      : _calculatePoint(point.xValue, point.yValue, xAxis, yAxis,
          chart._requireInvertedAxis, series, rect);
  point.region = Rect.fromLTWH(currentPoint.x - markerWidth,
      currentPoint.y - markerHeight, 2 * markerWidth, 2 * markerHeight);
  point.markerPoint = currentPoint;
  if (series._seriesType == 'rangearea') {
    num value1, value2;
    value1 = (point.low != null && point.high != null && point.low < point.high)
        ? point.high
        : point.low;
    value2 = (point.low != null && point.high != null && point.low > point.high)
        ? point.high
        : point.low;
    point.markerPoint = _calculatePoint(
        point.xValue,
        yAxis.isInversed ? value2 : value1,
        xAxis,
        yAxis,
        chart._requireInvertedAxis,
        series,
        rect);
    point.markerPoint2 = _calculatePoint(
        point.xValue,
        yAxis.isInversed ? value1 : value2,
        xAxis,
        yAxis,
        chart._requireInvertedAxis,
        series,
        rect);
    point.region = Rect.fromLTRB(
        point.markerPoint.x - markerWidth,
        point.markerPoint.y - markerHeight,
        point.markerPoint.x + markerWidth,
        point.markerPoint2.y);
  }
}

///Finding tooltip region
void _calculateTooltipRegion(
    CartesianChartPoint<dynamic> point,
    int seriesIndex,
    XyDataSeries<dynamic, dynamic> series,
    SfCartesianChart chart) {
  final ChartAxis xAxis = series._xAxis;
  final ChartAxis yAxis = series._yAxis;
  if (series.enableTooltip != null &&
      series.enableTooltip &&
      point != null &&
      !point.isGap &&
      !point.isDrop) {
    final List<String> regionData = <String>[];
    String date;
    final List<dynamic> regionRect = <dynamic>[];
    if (xAxis is DateTimeAxis) {
      final DateFormat dateFormat =
          xAxis.dateFormat ?? xAxis._getLabelFormat(xAxis);
      date =
          dateFormat.format(DateTime.fromMillisecondsSinceEpoch(point.xValue));
    }
    xAxis is CategoryAxis
        ? regionData.add(point.x.toString())
        : xAxis is DateTimeAxis
            ? regionData.add(date.toString())
            : regionData.add(_getLabelValue(
                    point.xValue, xAxis, chart.tooltipBehavior.decimalPlaces)
                .toString());
    if (series._seriesType.contains('range')) {
      regionData.add(
          _getLabelValue(point.high, yAxis, chart.tooltipBehavior.decimalPlaces)
              .toString());
      regionData.add(
          _getLabelValue(point.low, yAxis, chart.tooltipBehavior.decimalPlaces)
              .toString());
    } else {
      regionData.add(_getLabelValue(
              point.yValue, yAxis, chart.tooltipBehavior.decimalPlaces)
          .toString());
    }
    regionData.add(series.name ?? 'series $seriesIndex');
    regionRect.add(point.region);
    regionRect.add((series._isRectSeries)
        ? series._seriesType == 'column' ||
                series._seriesType.contains('stackedcolumn')
            ? point.yValue > 0
                ? point.region.topCenter
                : point.region.bottomCenter
            : point.region.topCenter
        : (series._seriesType == 'rangearea'
            ? Offset(point.markerPoint.x,
                (point.markerPoint.y + point.markerPoint2.y) / 2)
            : point.region.center));
    regionRect.add(point.pointColorMapper);
    regionRect.add(point.bubbleSize);
    regionRect.add(point);
    if (series._seriesType.contains('stacked')) {
      regionData.add((point.cumulativeValue).toString());
    }
    series._regionalData[regionRect] = regionData;
  }
}

/// Store the marker points before rendering
void _storeMarkerRegion(XyDataSeries<dynamic, dynamic> series) {
  if (series._seriesType == 'scatter') {
    series._markerShapes = <Path>[];
    for (int i = 0; i < series._dataPoints.length; i++) {
      final CartesianChartPoint<dynamic> point = series._dataPoints[i];
      final DataMarkerType markerType = series.markerSettings.shape;
      final Size size =
          Size(series.markerSettings.width, series.markerSettings.height);
      series._markerShapes.add(_getMarkerShapes(markerType,
          Offset(point.markerPoint.x, point.markerPoint.y), size, series));
    }
  } else {
    if (series.markerSettings.isVisible) {
      series._markerShapes = <Path>[];
      series._markerShapes2 = <Path>[];
      for (int i = 0; i < series._dataPoints.length; i++) {
        final CartesianChartPoint<dynamic> point = series._dataPoints[i];
        final DataMarkerType markerType = series.markerSettings.shape;
        final Size size =
            Size(series.markerSettings.width, series.markerSettings.height);
        series._markerShapes.add(_getMarkerShapes(markerType,
            Offset(point.markerPoint.x, point.markerPoint.y), size, series));
        if (series._seriesType.contains('range')) {
          series._markerShapes2.add(_getMarkerShapes(
              markerType,
              Offset(point.markerPoint2.x, point.markerPoint2.y),
              size,
              series));
        }
      }
    }
  }
}

void _renderSeriesElements(
  Canvas canvas,
  CartesianSeries<dynamic, dynamic> series, [
  Animation<double> animationController,
  Color scatterColor,
  Color scatterBorderColor,
]) {
  Paint strokePaint, fillPaint;
  final Size size =
      Size(series.markerSettings.width, series.markerSettings.height);
  final DataMarkerType markerType = series.markerSettings.shape;
  CartesianChartPoint<dynamic> point;
  Color _borderColor;
  final bool hasPointColor = (series.pointColorMapper != null) ? true : false;
  final double opacity =
      (animationController != null) ? animationController.value : 1;
  for (int pointIndex = 0;
      pointIndex < series._dataPoints.length;
      pointIndex++) {
    point = series._dataPoints[pointIndex];
    _borderColor = series.markerSettings.borderColor ?? series._seriesColor;
    strokePaint = Paint()
      ..color = point.isEmpty == true
          ? (series.emptyPointSettings.borderWidth == 0
              ? Colors.transparent
              : series.emptyPointSettings.borderColor.withOpacity(opacity))
          : (series.markerSettings.borderWidth == 0
              ? Colors.transparent
              : ((hasPointColor && point.pointColorMapper != null)
                  ? point.pointColorMapper.withOpacity(opacity)
                  : _borderColor.withOpacity(opacity)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = point.isEmpty == true
          ? series.emptyPointSettings.borderWidth
          : series.markerSettings.borderWidth;

    if (series.gradient != null && series.markerSettings.borderColor == null) {
      strokePaint = _getLinearGradientPaint(
          series.gradient,
          _getMarkerShapes(
                  markerType,
                  Offset(point.markerPoint.x, point.markerPoint.y),
                  size,
                  series)
              .getBounds(),
          series._chart._requireInvertedAxis);
      strokePaint.style = PaintingStyle.stroke;
      strokePaint.strokeWidth = point.isEmpty == true
          ? series.emptyPointSettings.borderWidth
          : series.markerSettings.borderWidth;
    }

    fillPaint = Paint()
      ..color = point.isEmpty == true
          ? series.emptyPointSettings.color
          : series.markerSettings.color != Colors.transparent
              ? series.markerSettings.color.withOpacity(opacity)
              : series.markerSettings.color
      ..style = PaintingStyle.fill;
    final bool isScatter = series._seriesType == 'scatter';

    /// Render marker points
    if ((series.markerSettings.isVisible || isScatter) &&
        point.isVisible &&
        point.isGap != true &&
        series._markerShapes != null &&
        series._markerShapes.isNotEmpty &&
        (!isScatter || series.markerSettings.shape == DataMarkerType.image)) {
      series.drawDataMarker(pointIndex, canvas, fillPaint, strokePaint,
          point.markerPoint.x, point.markerPoint.y);
      if (series.markerSettings.shape == DataMarkerType.image) {
        _drawImageMarker(
            series, canvas, point.markerPoint.x, point.markerPoint.y);
        if (series._seriesType.contains('range'))
          _drawImageMarker(
              series, canvas, point.markerPoint2.x, point.markerPoint2.y);
      }
    }
  }
}

/// Paint the image marker
void _drawImageMarker(CartesianSeries<dynamic, dynamic> series, Canvas canvas,
    double pointX, double pointY) {
  if (series.markerSettings._image != null) {
    final double imageWidth = 2 * series.markerSettings.width;
    final double imageHeight = 2 * series.markerSettings.height;
    final Rect positionRect = Rect.fromLTWH(pointX - imageWidth / 2,
        pointY - imageHeight / 2, imageWidth, imageHeight);
    paintImage(
        canvas: canvas,
        rect: positionRect,
        image: series.markerSettings._image,
        fit: BoxFit.fill);
  }
}

/// This method is for to calculate and rendering the length and Offsets of the dashed lines
void _drawDashedLine(
    Canvas canvas, List<double> dashArray, Paint paint, Path path) {
  bool even = false;
  for (int i = 1; i < dashArray.length; i = i + 2) {
    if (dashArray[i] == 0) {
      even = true;
    }
  }
  if (even == false) {
    paint.isAntiAlias = false;
    canvas.drawPath(
        _dashPath(
          path,
          dashArray: _CircularIntervalList<double>(dashArray),
        ),
        paint);
  } else
    canvas.drawPath(path, paint);
}
