part of charts;

/// Customizes the tooltip.
class TooltipBehavior extends ChartBehavior {
  TooltipBehavior(
      {ChartTextStyle textStyle,
      ActivationMode activationMode,
      int animationDuration,
      bool enable,
      double opacity,
      Color borderColor,
      double borderWidth,
      double duration,
      bool shouldAlwaysShow,
      double elevation,
      bool canShowMarker,
      ChartAlignment textAlignment,
      int decimalPlaces,
      TooltipPosition tooltipPosition,
      this.color,
      this.header,
      this.format,
      this.builder,
      this.shadowColor})
      : animationDuration = animationDuration ?? 350,
        textAlignment = textAlignment ?? ChartAlignment.center,
        textStyle = textStyle ?? ChartTextStyle(fontSize: 12),
        activationMode = activationMode ?? ActivationMode.singleTap,
        borderColor = borderColor ?? Colors.transparent,
        borderWidth = borderWidth ?? 0,
        duration = duration ?? 3000,
        enable = enable ?? false,
        opacity = opacity ?? 1,
        shouldAlwaysShow = shouldAlwaysShow ?? false,
        canShowMarker = canShowMarker ?? true,
        tooltipPosition = tooltipPosition ?? TooltipPosition.auto,
        elevation = elevation ?? 5.0,
        decimalPlaces = decimalPlaces ?? 3;

  ///Toggles the visibility of the tooltip.
  ///
  ///Defaults to false
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true),
  ///        ));
  ///}
  ///```
  final bool enable;

  ///Color of the tooltip.
  ///
  ///Defaults to null
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true, color: Colors.yellow),
  ///        ));
  ///}
  ///```
  final Color color;

  /// Header of the tooltip. By default, the series name will be displayed in the header.
  ///
  ///Defaults to ‘’
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true, header: 'Default'),
  ///        ));
  ///}
  ///```
  final String header;

  ///Opacity of the tooltip. The value ranges from 0 to 1.
  ///
  ///Defaults to 1
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true, opacity: 0.7),
  ///        ));
  ///}
  ///```
  final double opacity;

  ///Customizes the tooltip text
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(
  ///           enable: true,
  ///            textStyle: ChartTextStyle(color: Colors.green)),
  ///        ));
  ///}
  ///```
  final ChartTextStyle textStyle;

  ///Specifies the number decimals to be displayed in tooltip text
  ///
  ///Defaults to 3
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(
  ///           enable: true, decimalPlaces:5),
  ///        ));
  ///}
  ///```
  final int decimalPlaces;

  _TooltipPainter _painter;

  ///Formats the tooltip text. By default, the tooltip will be rendered with x and y-values.
  ///You can add prefix or suffix to x, y, and series name values in the
  ///tooltip by formatting them.
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true, format: '{value}%'),
  ///        ));
  ///}
  ///```
  final String format;

  ///Duration for animating the tooltip.
  ///
  ///Defaults to 350
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true, animationDuration: 1000),
  ///        ));
  ///}
  ///```
  final int animationDuration;

  ///Toggles the visibility of the marker in the tooltip.
  ///
  ///Defaults to true
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true, canShowMarker: true),
  ///        ));
  ///}
  ///```
  final bool canShowMarker;

  ///Gesture for activating the tooltip. Tooltip can be activated in tap,
  ///double tap, and long press.
  ///Defaults to ActivationMode.tap
  ///
  ///Also refer [ActivationMode]
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(
  ///           enable: true,
  ///           activationMode: ActivationMode.doubleTap),
  ///        ));
  ///}
  ///```
  final ActivationMode activationMode;

  ///Border color of the tooltip.
  ///
  ///Defaults to Colors.transparent
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true, borderColor: Colors.red),
  ///        ));
  ///}
  ///```
  final Color borderColor;

  ///Border width of the tooltip.
  ///
  ///Defaults to 0
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(
  ///           enable: true,
  ///           borderWidth: 2,
  ///           borderColor: Colors.red
  ///         ),
  ///        ));
  ///}
  ///```
  final double borderWidth;

  ///Builder of the tooltip.
  ///
  ///Defaults to null
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(
  ///           enable: true,
  ///           builder: (dynamic data, dynamic point,
  ///           dynamic series, int pointIndex, int seriesIndex) {
  ///           return Container(
  ///              height: 50,
  ///              width: 100,
  ///              decoration: const BoxDecoration(
  ///              color: Color.fromRGBO(66, 244, 164, 1)),
  ///              child: Row(
  ///              children: <Widget>[
  ///              Container(
  ///              width: 50,
  ///              child: Image.asset('images/bike.png')),],
  ///         ));
  ///         }),
  ///        ));
  ///}
  ///```
  final ChartWidgetBuilder<dynamic> builder;

  _TooltipTemplate _tooltipTemplate;

  ///Color of the tooltip shadow.
  ///
  ///Defaults to null
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true, shadowColor: Colors.green),
  ///        ));
  ///}
  ///```
  final Color shadowColor;

  ///Elevation of the tooltip.
  ///
  ///Defaults to 5.0
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true, elevation: 10),
  ///        ));
  ///}
  ///```
  final double elevation;

  ///Shows or hides the tooltip. By default, the tooltip will be hidden on touch.
  ///To avoid this, set this property to true.
  ///
  ///Defaults to false
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true, shouldAlwaysShow: true),
  ///        ));
  ///}
  ///```
  final bool shouldAlwaysShow;

  ///Duration for displaying the tooltip.
  ///
  ///Defaults to 3000
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true, duration: 1000),
  ///        ));
  ///}
  ///```
  final double duration;

  ///Alignment of the text in the tooltip
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true,textAlignment : ChartAlignment.near),
  ///        ));
  ///}
  ///```
  final ChartAlignment textAlignment;

  ///Show tooltip at tapped position
  ///
  ///Defaults to TooltipPosition.auto
  ///
  ///```dart
  ///Widget build(BuildContext context) {
  ///    return Container(
  ///        child: SfCartesianChart(
  ///           tooltipBehavior: TooltipBehavior(enable: true,
  ///           tooltipPosition: TooltipPosition.pointer),
  ///        ));
  ///}
  ///```
  final TooltipPosition tooltipPosition;

  _ChartTooltipRenderer chartTooltip;

  /// Displays the tooltip at the specified x and y-positions.
  ///
  ///
  /// x & y - logical pixel values to position the tooltip.
  ///
  // shouldInsidePointRegion - determines if whether the given pixel values remains within point region.
  // Defaults to true.
  void showByPixel(double x, double y) {
    //, [bool shouldInsidePointRegion]) {
    final dynamic chart = chartTooltip?.chartWidget;
    bool isInsidePointRegion;
    if (chart is SfCartesianChart) {
      for (int i = 0; i < chart._chartSeries.visibleSeries.length; i++) {
        final dynamic series = chart._chartSeries.visibleSeries[i];
        if (series._visible &&
            series.enableTooltip &&
            series._regionalData != null) {
          final double padding = (series._seriesType == 'bubble' ||
                  series._seriesType == 'scatter' ||
                  series._seriesType.contains('column') ||
                  series._seriesType.contains('bar'))
              ? 0
              : 15; // regional padding to detect smooth touch
          series._regionalData.forEach((dynamic regionRect, dynamic values) {
            final Rect region = regionRect[0];
            final Rect paddedRegion = Rect.fromLTRB(
                region.left - padding,
                region.top - padding,
                region.right + padding,
                region.bottom + padding);
            if (paddedRegion.contains(Offset(x, y))) isInsidePointRegion = true;
          });
        }
      }
    }
    if (chartTooltip != null &&
        activationMode != ActivationMode.none &&
        x != null &&
        y != null) {
      if (!(chart is SfCartesianChart) || (isInsidePointRegion ?? false)) {
        chartTooltip?.state?._needMarker = true;
        chartTooltip?.state?.showTooltip(x, y);
      } else if (chartTooltip.chartWidget.tooltipBehavior._painter != null) {
        chartTooltip?.state?.show = true;
        chartTooltip?.state?._needMarker = false;
        chartTooltip.chartWidget.tooltipBehavior._painter._showChartAreaTooltip(
            Offset(x, y), chart.primaryXAxis, chart.primaryYAxis);
      }
    }
  }

  /// Displays the tooltip at the specified x and y-values.
  ///
  ///
  /// x & y - x & y point values at which the tooltip needs to be shown.
  ///
// shouldInsidePointRegion - determines if whether the given pixel values remains within point region.
// Defaults to true.
  ///
  /// xAxisName - name of the x axis the given point must be bind to.
  ///
  /// yAxisName - name of the y axis the given point must be bind to.
  void show(dynamic x, double y, [String xAxisName, String yAxisName]) {
    final SfCartesianChart chart = chartTooltip.chartWidget;
    bool isInsidePointRegion = false;
    ChartAxis xAxis, yAxis;
    if (xAxisName != null && yAxisName != null)
      for (ChartAxis axis in chart._chartAxis._axisCollections) {
        if (axis._name == xAxisName)
          xAxis = axis;
        else if (axis._name == yAxisName) yAxis = axis;
      }
    else {
      xAxis = chart.primaryXAxis;
      yAxis = chart.primaryYAxis;
    }
    final _ChartLocation position = _calculatePoint(
        x is DateTime ? x.millisecondsSinceEpoch : x,
        y,
        xAxis,
        yAxis,
        chart._requireInvertedAxis,
        null,
        chart._chartAxis._axisClipRect);
    for (int i = 0; i < chart._chartSeries.visibleSeries.length; i++) {
      final dynamic series = chart._chartSeries.visibleSeries[i];
      if (series._visible &&
          series.enableTooltip &&
          series._regionalData != null) {
        final double padding = (series._seriesType == 'bubble' ||
                series._seriesType == 'scatter' ||
                series._seriesType.contains('column') ||
                series._seriesType.contains('bar'))
            ? 0
            : 15; // regional padding to detect smooth touch
        series._regionalData.forEach((dynamic regionRect, dynamic values) {
          final Rect region = regionRect[0];
          final Rect paddedRegion = Rect.fromLTRB(
              region.left - padding,
              region.top - padding,
              region.right + padding,
              region.bottom + padding);
          if (paddedRegion.contains(Offset(position.x, position.y)))
            isInsidePointRegion = true;
        });
      }
    }
    if (isInsidePointRegion ?? false) {
      chartTooltip?.state?._needMarker = true;
      chartTooltip?.state?.showTooltip(position.x, position.y);
    } else {
      chartTooltip?.state?.show = true;
      chartTooltip?.state?._needMarker = false;
      chartTooltip.chartWidget.tooltipBehavior._painter
          ._showChartAreaTooltip(Offset(position.x, position.y), xAxis, yAxis);
    }
  }

  /// Displays the tooltip at the specified series and point index.
  ///
  ///
  /// seriesIndex - index of the series for which the pointIndex is specified
  ///
  /// pointIndex - index of the point for which the tooltip should be shown
  void showByIndex(int seriesIndex, int pointIndex) {
    dynamic x, y;
    if (chartTooltip.chartWidget is SfCartesianChart) {
      if (_validIndex(pointIndex, seriesIndex, chartTooltip.chartWidget)) {
        final CartesianSeries<dynamic, dynamic> cSeries =
            chartTooltip.chartWidget.series[seriesIndex];
        if (cSeries._visible) {
          x = cSeries._dataPoints[pointIndex].markerPoint.x;
          y = cSeries._dataPoints[pointIndex].markerPoint.y;
        }
      }
    } else if (chartTooltip.chartWidget is SfCircularChart) {
      final ChartPoint<dynamic> chartPoint = chartTooltip.chartWidget
          ._chartSeries.visibleSeries[seriesIndex]._renderPoints[pointIndex];
      final Offset position = _degreeToPoint(
          chartPoint.midAngle,
          (chartPoint.innerRadius + chartPoint.outerRadius) / 2,
          chartPoint.center);
      x = position.dx;
      y = position.dy;
    } else if (pointIndex != null) {
      chartTooltip.chartWidget._chartState._tooltipPointIndex = pointIndex;
      final Offset position = chartTooltip
          .chartWidget.series._renderPoints[pointIndex].region.center;
      x = position.dx;
      y = position.dy;
    }
    if (chartTooltip != null &&
        activationMode != ActivationMode.none &&
        x != null &&
        y != null) {
      chartTooltip?.state?.showTooltip(x, y);
    }
  }

  /// Hides the tooltip if it is displayed.
  void hide() => _painter._calculateLocation(Offset(null, null));

  /// Draws tooltip
  @override
  void onPaint(Canvas canvas) {
    if (_painter != null) {
      _painter._renderTooltip(canvas);
    }
  }

  /// Performs the double-tap action of appropriate point.
  @override
  void onDoubleTap(double xPos, double yPos) => showByPixel(xPos, yPos);

  /// Performs the double-tap action of appropriate point.
  @override
  void onLongPress(double xPos, double yPos) => showByPixel(xPos, yPos);

  /// Performs the touch-down action of appropriate point.
  @override
  void onTouchDown(double xPos, double yPos) => showByPixel(xPos, yPos);

  /// Performs the touch move action of chart.
  @override
  void onTouchMove(double xPos, double yPos) {
    // Not valid for tooltip
  }

  /// Performs the touch move action of chart.
  @override
  void onTouchUp(double xPos, double yPos) => showByPixel(xPos, yPos);
}
