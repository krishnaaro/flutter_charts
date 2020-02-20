part of charts;

// ignore: must_be_immutable
class _ChartTooltipRenderer extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  _ChartTooltipRenderer({this.chartWidget});

  final dynamic chartWidget;

  _ChartTooltipRendererState state;

  @override
  State<StatefulWidget> createState() {
    return _ChartTooltipRendererState();
  }
}

class _ChartTooltipRendererState extends State<_ChartTooltipRenderer>
    with SingleTickerProviderStateMixin {
  /// Animation controller for series
  AnimationController animationController;

  /// Repaint notifier for crosshair container
  ValueNotifier<int> tooltipRepaintNotifier;

  bool show;
  //ignore: prefer_final_fields
  bool _needMarker = true;

  @override
  void initState() {
    show = false;
    tooltipRepaintNotifier = ValueNotifier<int>(0);
    animationController = AnimationController(vsync: this)
      ..addListener(repaintTooltipElements);
    super.initState();
  }

  @override
  void dispose() {
    if (animationController != null) {
      animationController.removeListener(repaintTooltipElements);
      animationController.dispose();
      animationController = null;
    }
    super.dispose();
  }

  void repaintTooltipElements() {
    tooltipRepaintNotifier.value++;
  }

  void showTooltip(double x, double y) {
    if (x != null &&
        y != null &&
        widget.chartWidget.tooltipBehavior._painter != null) {
      show = true;
      widget.chartWidget.tooltipBehavior._painter.show(x, y);
    }
  }

  void hide() {}

  @override
  Widget build(BuildContext context) {
    widget.state = this;
    animationController.duration = const Duration(milliseconds: 300);
    final Animation<double> tooltipAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.1, 0.8, curve: Curves.decelerate),
    ));
    animationController.forward(from: 0.0);
    final _TooltipPainter tooltipPainter = _TooltipPainter(
        tooltipAnimation: tooltipAnimation,
        chartTooltipState: this,
        notifier: tooltipRepaintNotifier,
        animationController: animationController);
    tooltipPainter._chart = widget.chartWidget;
    tooltipPainter.tooltip = widget.chartWidget.tooltipBehavior;
    tooltipPainter._chartState = widget.chartWidget._chartState;
    widget.chartWidget.tooltipBehavior._painter = tooltipPainter;
    return Container(child: CustomPaint(painter: tooltipPainter));
  }
}

class _TooltipPainter extends CustomPainter {
  _TooltipPainter(
      {this.chartTooltipState,
      this.animationController,
      this.tooltipAnimation,
      ValueNotifier<num> notifier})
      : super(repaint: notifier);
  double pointerLength = 10;
  double nosePointY = 0;
  double nosePointX = 0;
  double totalWidth = 0;
  double x;
  double y;
  double xPos;
  double yPos;
  ValueNotifier<int> valueNotifier;
  bool isTop = false;
  double borderRadius = 5;
  Path arrowPath = Path();
  bool canResetPath = false;
  Timer timer;
  bool isLeft = false;
  bool isRight = false;
  Animation<double> tooltipAnimation;
  dynamic _chart;
  bool enable;
  double padding = 0;
  String stringValue;
  String header;
  Rect boundaryRect = const Rect.fromLTWH(0, 0, 0, 0);
  dynamic tooltip;
  dynamic _chartState;
  dynamic currentSeries;
  num pointIndex;
  DataMarkerType markerType;
  double markerSize;
  Color markerColor;
  XyDataSeries<dynamic, dynamic> series;

  final _ChartTooltipRendererState chartTooltipState;

  final AnimationController animationController;

  // ignore:unused_element
  void _renderTooltipView(Offset position) {
    if (tooltip._painter._chart is SfCartesianChart) {
      _renderCartesianChartTooltip(position);
    } else if (tooltip._painter._chart is SfCircularChart) {
      _renderCircularChartTooltip(position);
    } else {
      _renderTriangularChartTooltip(position);
    }
  }

  void _renderCartesianChartTooltip(Offset position) {
    final SfCartesianChart chart = tooltip._painter._chart;
    chart.tooltipBehavior._painter.boundaryRect =
        chart._chartAxis._axisClipRect;
    bool isContains = false;
    if (chart._chartAxis._axisClipRect.contains(position)) {
      for (int i = 0; i < chart._chartSeries.visibleSeries.length; i++) {
        series = chart._chartSeries.visibleSeries[i];
        if (series._visible &&
            series.enableTooltip &&
            series._regionalData != null) {
          int count = 0;
          final double padding = (series._seriesType == 'bubble' ||
                  series._seriesType == 'scatter' ||
                  series._seriesType.contains('column') ||
                  series._seriesType.contains('bar'))
              ? 0
              : 15; // regional padding to detect smooth touch
          series._regionalData.forEach((dynamic regionRect, dynamic values) {
            final Rect region = regionRect[0];
            final double left = region.left - padding;
            final double right = region.right + padding;
            final double top = region.top - padding;
            final double bottom = region.bottom + padding;
            final Rect paddedRegion = Rect.fromLTRB(left, top, right, bottom);
            if (paddedRegion.contains(position)) {
              currentSeries = series;
              pointIndex = count;
              markerType = series.markerSettings.shape;
              markerColor = regionRect[2] != null
                  ? regionRect[2]
                  : series.markerSettings.borderColor ?? series._seriesColor;
              Offset tooltipPosition = regionRect[1];
              Offset padding;
              if (series._seriesType == 'bubble') {
                padding = Offset(region.center.dx - region.centerLeft.dx,
                    2 * (region.center.dy - region.topCenter.dy));
                tooltipPosition = Offset(tooltipPosition.dx, paddedRegion.top);
              } else if (series._seriesType == 'scatter') {
                padding = Offset(series.markerSettings.width,
                    series.markerSettings.height / 2);
                tooltipPosition =
                    Offset(tooltipPosition.dx, tooltipPosition.dy);
              } else {
                padding = (series.markerSettings.isVisible)
                    ? Offset(
                        series.markerSettings.width / 2,
                        series.markerSettings.height / 2 +
                            series.markerSettings.borderWidth / 2)
                    : const Offset(2, 2);
              }
              if (series._isRectSeries &&
                  chart.tooltipBehavior.tooltipPosition ==
                      TooltipPosition.pointer) {
                tooltipPosition = position;
              }
              chart.tooltipBehavior._painter.padding = padding.dy;
              String header = chart.tooltipBehavior.header;
              header = (header == null)
                  ? series._seriesName != null ? series._seriesName : null
                  : header;
              chart.tooltipBehavior._painter.header = header;
              _calculateCartesianTooltipText(
                  chart, series, regionRect, values, tooltipPosition);
              isContains = true;
            } else {
              if (!isContains) {
                chart.tooltipBehavior.hide();
              }
            }
            count++;
          });
        }
      }
    } else {
      chart.tooltipBehavior.hide();
    }
  }

  void _calculateCartesianTooltipText(
      SfCartesianChart chart,
      XyDataSeries<dynamic, dynamic> series,
      dynamic regionRect,
      dynamic values,
      Offset tooltipPosition) {
    if (chart.tooltipBehavior.format != null) {
      String resultantString = series._seriesType.contains('range')
          ? (chart.tooltipBehavior.format
              .replaceAll('point.x', values[0])
              .replaceAll('point.high', values[1])
              .replaceAll('point.low', values[2])
              .replaceAll('series.name', values[3] ?? 'series.name'))
          : (chart.tooltipBehavior.format
              .replaceAll('point.x', values[0])
              .replaceAll('point.y', values[1])
              .replaceAll('series.name', values[2] ?? 'series.name')
              .replaceAll('point.size', regionRect[3].toString()));
      if (series._seriesType.contains('stacked')) {
        resultantString = chart.tooltipBehavior.format
            .replaceAll('point.cumulativeValue', values[3]);
      }
      chart.tooltipBehavior._painter.stringValue = resultantString;
      chart.tooltipBehavior._painter._calculateLocation(tooltipPosition);
    } else {
      if (series._xAxis is! DateTimeAxis && (values[0].contains('.'))) {
        final List<String> val = values[0].split('.');
        final dynamic len = val[1].length;
        if (len < 3)
          chart.tooltipBehavior._painter.stringValue =
              values[0] + ' : ' + values[1];
        else
          chart.tooltipBehavior._painter.stringValue =
              values[0] + ' : ' + values[1];
      } else {
        chart.tooltipBehavior._painter.stringValue =
            series._seriesType.contains('range')
                ? (values[0] + '\nHigh: ' + values[1] + '\nLow: ' + values[2])
                : (values[0] + ' : ' + values[1]);
      }
      chart.tooltipBehavior._painter._calculateLocation(tooltipPosition);
    }
  }

  void _renderCircularChartTooltip(Offset position) {
    final SfCircularChart chart = tooltip._painter._chart;
    chart.tooltipBehavior._painter.boundaryRect =
        chart._chartState.chartContainerRect;
    final _Region pointRegion = _getPointRegion(chart, position);
    if (pointRegion != null &&
        chart._chartSeries.visibleSeries[pointRegion.seriesIndex]
            .enableTooltip) {
      final ChartPoint<dynamic> chartPoint = chart
          ._chartSeries
          .visibleSeries[pointRegion.seriesIndex]
          ._renderPoints[pointRegion.pointIndex];
      final Offset location =
          chart.tooltipBehavior.tooltipPosition == TooltipPosition.pointer
              ? position
              : _degreeToPoint(
                  chartPoint.midAngle,
                  (chartPoint.innerRadius + chartPoint.outerRadius) / 2,
                  chartPoint.center);
      currentSeries = pointRegion.seriesIndex;
      pointIndex = pointRegion.pointIndex;
      String header = chart.tooltipBehavior.header;
      header = (header == null)
          ? chart._chartSeries.visibleSeries[pointRegion.seriesIndex].name !=
                  null
              ? chart._chartSeries.visibleSeries[pointRegion.seriesIndex].name
              : null
          : header;
      chart.tooltipBehavior._painter.header = header;
      if (chart.tooltipBehavior.format != null) {
        final String resultantString = chart.tooltipBehavior.format
            .replaceAll('point.x', chartPoint.x.toString())
            .replaceAll('point.y', chartPoint.y.toString())
            .replaceAll(
                'series.name',
                chart._chartSeries.visibleSeries[pointRegion.seriesIndex]
                        .name ??
                    'series.name');
        chart.tooltipBehavior._painter.stringValue = resultantString;
        chart.tooltipBehavior._painter._calculateLocation(location);
      } else {
        chart.tooltipBehavior._painter.stringValue =
            chartPoint.x.toString() + ' : ' + chartPoint.y.toString();
        chart.tooltipBehavior._painter._calculateLocation(location);
      }
    } else {
      chart.tooltipBehavior.hide();
    }
  }

  void _renderTriangularChartTooltip(Offset position) {
    final dynamic chart = tooltip._painter._chart;
    chart.tooltipBehavior._painter.boundaryRect =
        chart._chartState.chartContainerRect;
    const num seriesIndex = 0;
    pointIndex = chart._chartState._tooltipPointIndex ??
        chart._chartState.currentActive.pointIndex;
    chart._chartState._tooltipPointIndex = null;
    if (chart.tooltipBehavior.enable) {
      final PointInfo<dynamic> chartPoint = chart
          ._chartSeries.visibleSeries[seriesIndex]._renderPoints[pointIndex];
      final Offset location =
          chart.tooltipBehavior.tooltipPosition == TooltipPosition.pointer
              ? position
              : chartPoint.symbolLocation;
      currentSeries = seriesIndex;
      pointIndex = pointIndex;
      String header = chart.tooltipBehavior.header;
      header = (header == null)
          ? chart._chartSeries.visibleSeries[seriesIndex].name != null
              ? chart._chartSeries.visibleSeries[seriesIndex].name
              : null
          : header;
      chart.tooltipBehavior._painter.header = header;
      if (chart.tooltipBehavior.format != null) {
        final String resultantString = chart.tooltipBehavior.format
            .replaceAll('point.x', chartPoint.x.toString())
            .replaceAll('point.y', chartPoint.y.toString())
            .replaceAll(
                'series.name',
                chart._chartSeries.visibleSeries[seriesIndex].name ??
                    'series.name');
        chart.tooltipBehavior._painter.stringValue = resultantString;
        chart.tooltipBehavior._painter._calculateLocation(location);
      } else {
        chart.tooltipBehavior._painter.stringValue =
            chartPoint.x.toString() + ' : ' + chartPoint.y.toString();
        chart.tooltipBehavior._painter._calculateLocation(location);
      }
    } else {
      chart.tooltipBehavior.hide();
    }
  }

  void _calculateLocation(Offset position) {
    x = position.dx;
    y = position.dy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (chartTooltipState.show) {
      if (_chart is SfCartesianChart) {
        final SfCartesianChart sfChart = _chart;
        sfChart.tooltipBehavior.onPaint(canvas);
      } else if (_chart is SfCircularChart) {
        final SfCircularChart sfCircularChart = _chart;
        sfCircularChart.tooltipBehavior.onPaint(canvas);
      } else if (_chart is SfPyramidChart) {
        final SfPyramidChart sfPyramidChart = _chart;
        sfPyramidChart.tooltipBehavior.onPaint(canvas);
      } else if (_chart is SfFunnelChart) {
        final SfFunnelChart sfFunnelChart = _chart;
        sfFunnelChart.tooltipBehavior.onPaint(canvas);
      }
    }
  }

  void _renderTooltip(Canvas canvas) {
    isLeft = false;
    isRight = false;
    double height = 0, width = 0, headerTextWidth = 0, headerTextHeight = 0;
    TooltipArgs tooltipArgs;
    markerSize = 0;

    if (x != null &&
        y != null &&
        stringValue != null &&
        _chart.onTooltipRender != null) {
      const num index = 0;
      tooltipArgs = TooltipArgs();
      tooltipArgs.text = stringValue;
      tooltipArgs.header = header;
      tooltipArgs.locationX = x;
      tooltipArgs.locationY = y;
      tooltipArgs.pointIndex = pointIndex;
      tooltipArgs.seriesIndex = _chart is SfCartesianChart
          ? currentSeries.segments[index]._seriesIndex
          : currentSeries;
      tooltipArgs.dataPoints = _chart
          ._chartSeries.visibleSeries[tooltipArgs.seriesIndex]._dataPoints;
      _chart.onTooltipRender(tooltipArgs);
      stringValue = tooltipArgs.text;
      header = tooltipArgs.header;
      x = tooltipArgs.locationX;
      y = tooltipArgs.locationY;
    }

    totalWidth = boundaryRect.left.toDouble() + boundaryRect.width.toDouble();
    final ChartTextStyle textStyle = ChartTextStyle(
        color: tooltip.textStyle.color ?? _chart._chartTheme.tooltipLabelColor,
        fontSize: tooltip.textStyle.fontSize,
        fontFamily: tooltip.textStyle.fontFamily,
        fontWeight: tooltip.textStyle.fontWeight,
        fontStyle: tooltip.textStyle.fontStyle);
    width = _measureText(stringValue, textStyle).width;
    height = _measureText(stringValue, textStyle).height;
    if (header != null && header.isNotEmpty) {
      final ChartTextStyle headerTextStyle = ChartTextStyle(
          color:
              tooltip.textStyle.color ?? _chart._chartTheme.tooltipLabelColor,
          fontSize: tooltip.textStyle.fontSize,
          fontFamily: tooltip.textStyle.fontFamily,
          fontStyle: tooltip.textStyle.fontStyle,
          fontWeight: FontWeight.bold);
      headerTextWidth = _measureText(header, headerTextStyle).width;
      headerTextHeight = _measureText(header, headerTextStyle).height + 10;
      width = width > headerTextWidth ? width : headerTextWidth;
    }

    if (width < 10) {
      width = 10; // minimum width for tooltip to render
      borderRadius = borderRadius > 5 ? 5 : borderRadius;
    }
    if (borderRadius > 15) {
      borderRadius = 15;
    }

    if (x != null &&
        y != null &&
        padding != null &&
        (stringValue != '' && stringValue != null ||
            header != '' && header != null)) {
      _calculateBackgroundRect(canvas, height, width, headerTextHeight);
    }
  }

  /// calculate tooltip rect and arrow head
  void _calculateBackgroundRect(
      Canvas canvas, double height, double width, double headerTextHeight) {
    double widthPadding = 15;
    if (_chart is SfCartesianChart &&
        tooltip.canShowMarker != null &&
        tooltip.canShowMarker &&
        chartTooltipState._needMarker) {
      markerSize = 5;
      widthPadding = 17;
    }

    Rect rect = Rect.fromLTWH(x, y, width + (2 * markerSize) + widthPadding,
        height + headerTextHeight + 10);
    final Rect newRect = Rect.fromLTWH(boundaryRect.left + 20, boundaryRect.top,
        boundaryRect.width - 40, boundaryRect.height);
    final Rect leftRect = Rect.fromLTWH(
        boundaryRect.left - 5,
        boundaryRect.top - 20,
        newRect.left - (boundaryRect.left - 5),
        boundaryRect.height + 40);
    final Rect rightRect = Rect.fromLTWH(newRect.right, boundaryRect.top - 20,
        (boundaryRect.right + 5) - newRect.right, boundaryRect.height + 40);

    if (leftRect.contains(Offset(x, y))) {
      isLeft = true;
      isRight = false;
    } else if (rightRect.contains(Offset(x, y))) {
      isLeft = false;
      isRight = true;
    }

    if (y > pointerLength + rect.height && y > boundaryRect.top) {
      if (_chart is SfCartesianChart) {
        if (currentSeries._seriesType == 'bubble') {
          padding = 2;
        }
      }
      isTop = true;
      xPos = x - (rect.width / 2);
      yPos = (y - rect.height) - padding;
      nosePointY = rect.top - padding;
      nosePointX = rect.left;
      final double tooltipRightEnd = x + (rect.width / 2);
      xPos = xPos < boundaryRect.left
          ? boundaryRect.left
          : tooltipRightEnd > totalWidth ? totalWidth - rect.width : xPos;
      yPos = yPos - (pointerLength / 2);
    } else {
      isTop = false;
      xPos = x - (rect.width / 2);
      yPos =
          ((y >= boundaryRect.top ? y : boundaryRect.top) + pointerLength / 2) +
              padding;
      nosePointX = rect.left;
      nosePointY = (y >= boundaryRect.top ? y : boundaryRect.top) + padding;
      final double tooltipRightEnd = x + (rect.width / 2);
      xPos = xPos < boundaryRect.left
          ? boundaryRect.left
          : tooltipRightEnd > totalWidth ? totalWidth - rect.width : xPos;
    }
    if (xPos <= boundaryRect.left + 5) {
      xPos = xPos + 5;
    } else if (xPos + rect.width >= totalWidth - 5) {
      xPos = xPos - 5;
    }
    rect = Rect.fromLTWH(xPos, yPos, rect.width, rect.height);
    _drawBackground(canvas, rect, nosePointX, nosePointY, borderRadius, isTop,
        arrowPath, isLeft, isRight, tooltipAnimation);
  }

  void _drawBackground(
      Canvas canvas,
      Rect rectF,
      double xPos,
      double yPos,
      double borderRadius,
      bool isTop,
      Path backgroundPath,
      bool isLeft,
      bool isRight,
      Animation<double> tooltipAnimation) {
    final double startArrow = pointerLength / 2;
    final double endArrow = pointerLength / 2;
    if (isTop) {
      _drawTooltip(
          canvas,
          isTop,
          rectF,
          xPos,
          yPos,
          xPos - startArrow,
          yPos - startArrow,
          xPos + endArrow,
          yPos - endArrow,
          borderRadius,
          backgroundPath,
          isLeft,
          isRight,
          tooltipAnimation);
    } else {
      _drawTooltip(
          canvas,
          isTop,
          rectF,
          xPos,
          yPos,
          xPos - startArrow,
          yPos + startArrow,
          xPos + endArrow,
          yPos + endArrow,
          borderRadius,
          backgroundPath,
          isLeft,
          isRight,
          tooltipAnimation);
    }
  }

  void _drawTooltip(
      Canvas canvas,
      bool isTop,
      Rect rectF,
      double xPos,
      double yPos,
      double startX,
      double startY,
      double endX,
      double endY,
      double borderRadius,
      Path backgroundPath,
      bool isLeft,
      bool isRight,
      Animation<double> tooltipAnimation) {
    double animationFactor = 0;
    if (tooltipAnimation == null) {
      animationFactor = 1;
    } else {
      animationFactor = tooltipAnimation.value;
    }
    backgroundPath.reset();
    if (!canResetPath) {
      if (isLeft) {
        startX = rectF.left + (2 * borderRadius);
        endX = startX + pointerLength;
      } else if (isRight) {
        startX = endX - pointerLength;
        endX = rectF.right - (2 * borderRadius);
      }

      final Rect rect = Rect.fromLTWH(
          rectF.width / 2 + (rectF.left - rectF.width / 2 * animationFactor),
          rectF.height / 2 + (rectF.top - rectF.height / 2 * animationFactor),
          rectF.width * animationFactor,
          rectF.height * animationFactor);

      final RRect tooltipRect = RRect.fromRectAndCorners(
        rect,
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      );
      _drawTooltipPath(canvas, tooltipRect, rect, backgroundPath, isTop, isLeft,
          isRight, startX, endX, animationFactor, xPos, yPos);

      final ChartTextStyle textStyle = ChartTextStyle(
          color: tooltip.textStyle.color?.withOpacity(tooltip.opacity) ??
              _chart._chartTheme.tooltipLabelColor,
          fontSize: tooltip.textStyle.fontSize * animationFactor,
          fontFamily: tooltip.textStyle.fontFamily,
          fontWeight: tooltip.textStyle.fontWeight,
          fontStyle: tooltip.textStyle.fontStyle);
      final Size result = _measureText(stringValue, textStyle);

      if (_chart is SfCartesianChart &&
          tooltip.canShowMarker &&
          chartTooltipState._needMarker) {
        _drawTootipMarker(canvas, tooltipRect, result, animationFactor);
      }
      _drawTooltipText(canvas, tooltipRect, textStyle, result, animationFactor);
      xPos = null;
      yPos = null;
    }
  }

  /// draw the tooltip rect path
  void _drawTooltipPath(
      Canvas canvas,
      RRect tooltipRect,
      Rect rect,
      Path backgroundPath,
      bool isTop,
      bool isLeft,
      bool isRight,
      double startX,
      double endX,
      double animationFactor,
      double xPos,
      double yPos) {
    double factor = 0;
    if (isTop && isRight) {
      factor = rect.bottom;
      backgroundPath.moveTo(rect.right - 20, factor);
      backgroundPath.lineTo(xPos, yPos);
      backgroundPath.lineTo(rect.right - 20, rect.top + rect.height / 2);
      backgroundPath.lineTo(rect.right - 20, factor);
    } else if (!isTop && isRight) {
      factor = rect.top;
      backgroundPath.moveTo(rect.right - 20, factor);
      backgroundPath.lineTo(xPos, yPos);
      backgroundPath.lineTo(rect.right - 20, rect.top + rect.height / 2);
      backgroundPath.lineTo(rect.right - 20, factor);
    } else if (isTop && isLeft) {
      factor = rect.bottom;
      backgroundPath.moveTo(rect.left + 20, factor);
      backgroundPath.lineTo(xPos, yPos);
      backgroundPath.lineTo(rect.left + 20, rect.top + rect.height / 2);
      backgroundPath.lineTo(rect.left + 20, factor);
    } else if (!isTop && isLeft) {
      factor = rect.top;
      backgroundPath.moveTo(rect.left + 20, factor);
      backgroundPath.lineTo(xPos, yPos);
      backgroundPath.lineTo(rect.left + 20, rect.top + rect.height / 2);
      backgroundPath.lineTo(rect.left + 20, factor);
    } else {
      if (isTop) {
        factor = tooltipRect.bottom;
      } else {
        factor = tooltipRect.top;
      }
      backgroundPath.moveTo(startX - ((endX - startX) / 4), factor);
      backgroundPath.lineTo(xPos, yPos);
      backgroundPath.lineTo(endX + ((endX - startX) / 4), factor);
      backgroundPath.lineTo(startX + ((endX - startX) / 4), factor);
    }
    final Paint fillPaint = Paint()
      ..color = (tooltip.color ?? _chart._chartTheme.tooltipFillColor)
          .withOpacity(tooltip.opacity)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..color = tooltip.borderColor == Colors.transparent
          ? Colors.transparent
          : tooltip.borderColor.withOpacity(tooltip.opacity)
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke
      ..strokeWidth = tooltip.borderWidth;
    tooltip.borderWidth == 0
        ? strokePaint.color = Colors.transparent
        : strokePaint.color = strokePaint.color;

    final Path tooltipPath = Path();
    tooltipPath.addRRect(tooltipRect);
    if (tooltip.elevation > 0) {
      if (tooltipRect.width * animationFactor > tooltipRect.width * 0.85) {
        canvas.drawShadow(arrowPath, tooltip.shadowColor ?? fillPaint.color,
            tooltip.elevation, true);
      }
      canvas.drawShadow(tooltipPath, tooltip.shadowColor ?? fillPaint.color,
          tooltip.elevation, true);
    }

    if (tooltipRect.width * animationFactor > tooltipRect.width * 0.85) {
      canvas.drawPath(arrowPath, fillPaint);
      canvas.drawPath(arrowPath, strokePaint);
    }
    canvas.drawPath(tooltipPath, fillPaint);
    canvas.drawPath(tooltipPath, strokePaint);
  }

  /// draw marker inside the tooltip
  void _drawTootipMarker(
      Canvas canvas, RRect tooltipRect, Size result, double animationFactor) {
    final Offset markerPoint = Offset(
        tooltipRect.left + tooltipRect.width / 2 - result.width / 2,
        ((tooltipRect.top + tooltipRect.height) - result.height / 2) -
            markerSize);
    final Path markerPath = _getMarkerShapes(
        markerType,
        markerPoint,
        Size((2 * markerSize) * animationFactor,
            (2 * markerSize) * animationFactor),
        series);

    if (series.markerSettings.shape == DataMarkerType.image) {
      _drawImageMarker(series, canvas, markerPoint.dx, markerPoint.dy);
    }

    Paint markerPaint = Paint();
    markerPaint.color = markerColor.withOpacity(tooltip.opacity);
    if (series.gradient != null) {
      markerPaint = _getLinearGradientPaint(
          series.gradient,
          _getMarkerShapes(
                  markerType,
                  Offset(markerPoint.dx, markerPoint.dy),
                  Size((2 * markerSize) * animationFactor,
                      (2 * markerSize) * animationFactor),
                  series)
              .getBounds(),
          series._chart._requireInvertedAxis);
    }
    canvas.drawPath(markerPath, markerPaint);
    final Paint markerBorderPaint = Paint();
    markerBorderPaint.color = Colors.white.withOpacity(tooltip.opacity);
    markerBorderPaint.strokeWidth = 1;
    markerBorderPaint.style = PaintingStyle.stroke;
    canvas.drawPath(markerPath, markerBorderPaint);
  }

  /// draw tooltip header, divider,text
  void _drawTooltipText(Canvas canvas, RRect tooltipRect,
      ChartTextStyle textStyle, Size result, double animationFactor) {
    const double padding = 10;
    if (header != null && header.isNotEmpty) {
      final ChartTextStyle headerTextStyle = ChartTextStyle(
          color: tooltip.textStyle.color?.withOpacity(tooltip.opacity) ??
              _chart._chartTheme.tooltipLabelColor,
          fontSize: tooltip.textStyle.fontSize * animationFactor,
          fontFamily: tooltip.textStyle.fontFamily,
          fontStyle: tooltip.textStyle.fontStyle,
          fontWeight: FontWeight.bold);
      final Size headerResult = _measureText(header, headerTextStyle);

      _drawText(
          tooltip,
          canvas,
          header,
          Offset(
              (tooltipRect.left + tooltipRect.width / 2) -
                  headerResult.width / 2,
              tooltipRect.top + padding / 2),
          headerTextStyle,
          0);

      final Paint dividerPaint = Paint();
      dividerPaint.color =
          _chart._chartTheme.tooltipLabelColor.withOpacity(tooltip.opacity);
      dividerPaint.strokeWidth = 0.5 * animationFactor;
      dividerPaint.style = PaintingStyle.stroke;

      canvas.drawLine(
          Offset(tooltipRect.left + padding,
              tooltipRect.top + headerResult.height + padding),
          Offset(tooltipRect.right - padding,
              tooltipRect.top + headerResult.height + padding),
          dividerPaint);

      _drawText(
          tooltip,
          canvas,
          stringValue,
          Offset(
              (tooltipRect.left + 2 * markerSize + tooltipRect.width / 2) -
                  result.width / 2,
              (tooltipRect.top + tooltipRect.height) - result.height - 5),
          textStyle,
          0);
    } else {
      _drawText(
          tooltip,
          canvas,
          stringValue,
          Offset(
              (tooltipRect.left + 2 * markerSize + tooltipRect.width / 2) -
                  result.width / 2,
              (tooltipRect.top + tooltipRect.height / 2) - result.height / 2),
          textStyle,
          0);
    }
  }

  ///draw tooltip text
  void _drawText(dynamic tooltip, Canvas canvas, String text, Offset point,
      ChartTextStyle style, int rotation) {
    TextAlign tooltipTextAlign = TextAlign.start;
    if (tooltip != null &&
        tooltip.format != null &&
        tooltip.format.isNotEmpty) {
      if (tooltip.textAlignment == ChartAlignment.near) {
        tooltipTextAlign = TextAlign.start;
      } else if (tooltip.textAlignment == ChartAlignment.center) {
        tooltipTextAlign = TextAlign.center;
      } else if (tooltip.textAlignment == ChartAlignment.far) {
        tooltipTextAlign = TextAlign.end;
      }
    }

    final Color color = style.color;
    final double fontSize = style.fontSize;
    final String fontFamily = style.fontFamily;
    final FontStyle fontStyle = style.fontStyle;
    final FontWeight fontWeight = style.fontWeight;
    final TextSpan span = TextSpan(
        text: text,
        style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontStyle: fontStyle,
            fontWeight: fontWeight));

    final TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        textAlign: tooltipTextAlign);
    tp.layout();
    canvas.save();
    canvas.translate(point.dx, point.dy);
    if (rotation != null && rotation > 0) {
      canvas.rotate(_degreeToRadian(rotation));
    }
    tp.paint(canvas, const Offset(0.0, 0.0));
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  void show(double x, double y) {
    if (tooltip.enable &&
        tooltip._painter != null &&
        tooltip._painter._chart._chartState.animateCompleted) {
      chartTooltipState.animationController.forward(from: 0.0);
      tooltip._painter.canResetPath = false;
      tooltip._painter._renderTooltipView(Offset(x, y));
      if (tooltip._painter.timer != null) {
        tooltip._painter.timer.cancel();
      }
      if (!tooltip.shouldAlwaysShow) {
        tooltip._painter.timer =
            Timer(Duration(milliseconds: tooltip.duration.toInt()), () {
          chartTooltipState.show = false;
          chartTooltipState.tooltipRepaintNotifier.value++;
          tooltip._painter.canResetPath = true;
        });
      }
    }
  }

  //this method shows the tooltip for any logical pixel outside point region
  //ignore: unused_element
  void _showChartAreaTooltip(
      Offset position, ChartAxis xAxis, ChartAxis yAxis) {
    if (tooltip.enable &&
        tooltip._painter != null &&
        tooltip._painter._chart._chartState.animateCompleted) {
      chartTooltipState.animationController.forward(from: 0.0);
      tooltip._painter.canResetPath = false;
      //render
      final SfCartesianChart chart = tooltip._painter._chart;
      chart.tooltipBehavior._painter.boundaryRect =
          chart._chartAxis._axisClipRect;
      if (chart._chartAxis._axisClipRect.contains(position)) {
        chart.tooltipBehavior._painter.currentSeries = chart.series[0];
        chart.tooltipBehavior._painter.series = chart.series[0];
        chart.tooltipBehavior._painter.padding = 5;
        chart.tooltipBehavior._painter.header = null;
        dynamic xValue = _pointToXValue(
            chart,
            xAxis,
            xAxis._bounds,
            position.dx -
                (chart._chartAxis._axisClipRect.left + xAxis.plotOffset),
            position.dy -
                (chart._chartAxis._axisClipRect.top + xAxis.plotOffset));
        dynamic yValue = _pointToYValue(
            chart,
            yAxis,
            yAxis._bounds,
            position.dx -
                (chart._chartAxis._axisClipRect.left + yAxis.plotOffset),
            position.dy -
                (chart._chartAxis._axisClipRect.top + yAxis.plotOffset));
        if (xAxis is DateTimeAxis)
          xValue = (xAxis.dateFormat ?? xAxis._getLabelFormat(xAxis))
              .format(DateTime.fromMillisecondsSinceEpoch(xValue.floor()));
        if (yAxis is DateTimeAxis)
          yValue = (yAxis.dateFormat ?? yAxis._getLabelFormat(yAxis))
              .format(DateTime.fromMillisecondsSinceEpoch(yValue.floor()));
        if (xAxis is CategoryAxis) {
          xValue = xAxis._visibleLabels[xValue.toInt()].text;
        }
        chart.tooltipBehavior._painter.stringValue =
            ' $xValue :  ${yValue.toStringAsFixed(2)} ';
        chart.tooltipBehavior._painter._calculateLocation(position);
      }
      if (tooltip._painter.timer != null) {
        tooltip._painter.timer.cancel();
      }
      if (!tooltip.shouldAlwaysShow) {
        tooltip._painter.timer =
            Timer(Duration(milliseconds: tooltip.duration.toInt()), () {
          chartTooltipState.show = false;
          chartTooltipState.tooltipRepaintNotifier.value++;
          tooltip._painter.canResetPath = true;
        });
      }
    }
  }
}
