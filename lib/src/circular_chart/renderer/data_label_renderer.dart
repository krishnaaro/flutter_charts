part of charts;

// ignore: must_be_immutable
class _CircularDataLabelRenderer extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  _CircularDataLabelRenderer({this.circularChart, this.show});

  final SfCircularChart circularChart;

  bool show;

  _CircularDataLabelRendererState state;

  @override
  State<StatefulWidget> createState() {
    return _CircularDataLabelRendererState();
  }
}

class _CircularDataLabelRendererState extends State<_CircularDataLabelRenderer>
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
    if (widget.circularChart._chartState.initialRender) {
      animationController.forward(from: 0.0);
    }
    return !widget.show
        ? Container()
        : Container(
            child: CustomPaint(
                painter: _CircularDataLabelPainter(
                    circularChart: widget.circularChart,
                    animation: dataLabelAnimation,
                    state: this,
                    notifier: dataLabelRepaintNotifier,
                    animationController: animationController)));
  }
}

class _CircularDataLabelPainter extends CustomPainter {
  _CircularDataLabelPainter(
      {this.circularChart,
      this.state,
      this.animationController,
      this.animation,
      ValueNotifier<num> notifier})
      : super(repaint: notifier);

  final SfCircularChart circularChart;

  final _CircularDataLabelRendererState state;

  final AnimationController animationController;

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    for (int seriesIndex = 0;
        seriesIndex < circularChart.series.length;
        seriesIndex++) {
      final CircularSeries<dynamic, dynamic> series =
          circularChart.series[seriesIndex];
      if (series.dataLabelSettings != null &&
          series.dataLabelSettings.isVisible) {
        _renderDataLabel(series, canvas, circularChart, seriesIndex, animation);
      }
    }
  }

  @override
  bool shouldRepaint(_CircularDataLabelPainter oldDelegate) => true;
}

void _renderDataLabel(CircularSeries<dynamic, dynamic> series, Canvas canvas,
    SfCircularChart chart, int seriesIndex, Animation<double> animation) {
  ChartPoint<dynamic> point;
  final DataLabelSettings dataLabel = series.dataLabelSettings;
  final num angle = dataLabel.angle;
  Offset labelLocation;
  const int labelPadding = 2;
  String label;
  final double animateOpacity = animation != null ? animation.value : 1;
  DataLabelRenderArgs dataLabelArgs;
  ChartTextStyle dataLabelStyle;
  final List<Rect> renderDataLabelRegions = <Rect>[];
  for (int pointIndex = 0;
      pointIndex < series._renderPoints.length;
      pointIndex++) {
    point = series._renderPoints[pointIndex];
    if (point.isVisible) {
      label = point.text;
      label = series._renderer
          .getLabelContent(series, point, pointIndex, seriesIndex, label);
      dataLabelStyle = dataLabel.textStyle;
      if (chart.onDataLabelRender != null) {
        dataLabelArgs = DataLabelRenderArgs();
        dataLabelArgs.text = label;
        dataLabelArgs.textStyle = dataLabelStyle;
        dataLabelArgs.series = series;
        dataLabelArgs.dataPoints = series._renderPoints;
        dataLabelArgs.pointIndex = pointIndex;
        chart.onDataLabelRender(dataLabelArgs);
        label = dataLabelArgs.text;
        dataLabelStyle = dataLabelArgs.textStyle;
      }
      dataLabelStyle = chart.onDataLabelRender == null
          ? series._renderer.getDataLabelStyle(
              series, point, pointIndex, seriesIndex, dataLabelStyle, chart)
          : dataLabelStyle;
      final Size textSize = _measureText(label, dataLabelStyle);
      if (series._seriesType == 'radialbar') {
        labelLocation = _degreeToPoint(point.startAngle,
            (point.innerRadius + point.outerRadius) / 2, point.center);
        labelLocation = Offset(
            (labelLocation.dx - textSize.width - 5) +
                (angle == 0 ? 0 : textSize.width / 2),
            (labelLocation.dy - textSize.height / 2) +
                (angle == 0 ? 0 : textSize.height / 2));
        point.labelRect = Rect.fromLTWH(
            labelLocation.dx - labelPadding,
            labelLocation.dy - labelPadding,
            textSize.width + (2 * labelPadding),
            textSize.height + (2 * labelPadding));
        _drawLabel(
            point.labelRect,
            labelLocation,
            label,
            null,
            canvas,
            series,
            point,
            pointIndex,
            seriesIndex,
            chart,
            dataLabelStyle,
            renderDataLabelRegions,
            animateOpacity);
      } else {
        _setLabelPosition(
            dataLabel,
            point,
            textSize,
            chart,
            canvas,
            renderDataLabelRegions,
            pointIndex,
            label,
            series,
            animateOpacity,
            dataLabelStyle,
            seriesIndex);
      }
    }
  }
}

void _setLabelPosition(
    DataLabelSettings dataLabel,
    ChartPoint<dynamic> point,
    Size textSize,
    SfCircularChart chart,
    Canvas canvas,
    List<Rect> renderDataLabelRegions,
    int pointIndex,
    String label,
    dynamic series,
    double animateOpacity,
    ChartTextStyle dataLabelStyle,
    int seriesIndex) {
  final num angle = dataLabel.angle;
  Offset labelLocation;
  final bool smartLabel = series.enableSmartLabels;
  const int labelPadding = 2;
  if (dataLabel.labelPosition == ChartDataLabelPosition.inside) {
    labelLocation = _degreeToPoint(point.midAngle,
        (point.innerRadius + point.outerRadius) / 2, point.center);
    labelLocation = Offset(
        labelLocation.dx -
            (textSize.width / 2) +
            (angle == 0 ? 0 : textSize.width / 2),
        labelLocation.dy -
            (textSize.height / 2) +
            (angle == 0 ? 0 : textSize.height / 2));
    point.labelRect = Rect.fromLTWH(
        labelLocation.dx - labelPadding,
        labelLocation.dy - labelPadding,
        textSize.width + (2 * labelPadding),
        textSize.height + (2 * labelPadding));
    final bool isDataLabelCollide =
        _isCollide(point.labelRect, renderDataLabelRegions);
    if (smartLabel && isDataLabelCollide) {
      point.saturationRegionOutside = true;
      point.renderPosition = ChartDataLabelPosition.outside;
      dataLabelStyle.color = dataLabel.textStyle.color ??
          _getSaturationColor(dataLabel.color ??
              (dataLabel.useSeriesColor
                  ? point.fill
                  : (chart.backgroundColor ??
                      (chart._chartTheme.brightness == Brightness.light
                          ? Colors.white
                          : Colors.black))));
      _renderOutsideDataLabel(
          canvas,
          label,
          point,
          textSize,
          pointIndex,
          series,
          smartLabel,
          seriesIndex,
          chart,
          dataLabelStyle,
          renderDataLabelRegions,
          animateOpacity);
    } else {
      point.renderPosition = ChartDataLabelPosition.inside;
      dataLabelStyle.color = dataLabel.textStyle.color ??
          _getSaturationColor(dataLabel.color ?? point.fill);
      if (isDataLabelCollide
          ? (dataLabel.labelIntersectAction == LabelIntersectAction.hide)
              ? false
              : true
          : true) {
        _drawLabel(
            point.labelRect,
            labelLocation,
            label,
            null,
            canvas,
            series,
            point,
            pointIndex,
            seriesIndex,
            chart,
            dataLabelStyle,
            renderDataLabelRegions,
            animateOpacity);
      }
    }
  } else {
    point.renderPosition = ChartDataLabelPosition.outside;
    _renderOutsideDataLabel(
        canvas,
        label,
        point,
        textSize,
        pointIndex,
        series,
        smartLabel,
        seriesIndex,
        chart,
        dataLabelStyle,
        renderDataLabelRegions,
        animateOpacity);
  }
}

void _renderOutsideDataLabel(
    Canvas canvas,
    String label,
    ChartPoint<dynamic> point,
    Size textSize,
    int pointIndex,
    CircularSeries<dynamic, dynamic> series,
    bool smartLabel,
    int seriesIndex,
    SfCircularChart chart,
    ChartTextStyle textStyle,
    List<Rect> renderDataLabelRegions,
    double animateOpacity) {
  Path connectorPath;
  Rect rect;
  Offset labelLocation;
  final EdgeInsets margin = series.dataLabelSettings.margin;
  final ConnectorLineSettings connector =
      series.dataLabelSettings.connectorLineSettings;
  connectorPath = Path();
  final num connectorLength = _percentToValue(
      connector.length != null ? connector.length : '10%', point.outerRadius);
  final Offset startPoint =
      _degreeToPoint(point.midAngle, point.outerRadius, point.center);
  final Offset endPoint = _degreeToPoint(
      point.midAngle, point.outerRadius + connectorLength, point.center);
  connectorPath.moveTo(startPoint.dx, startPoint.dy);
  if (connector.type == ConnectorType.line) {
    connectorPath.lineTo(endPoint.dx, endPoint.dy);
  }
  rect = _getDataLabelRect(point.dataLabelPosition, connector.type, margin,
      connectorPath, endPoint, textSize);
  point.labelRect = rect;
  labelLocation = Offset(rect.left + margin.left,
      rect.top + rect.height / 2 - textSize.height / 2);
  final Rect containerRect = chart._chartState.chartAreaRect;
  if (series.dataLabelSettings.builder == null) {
    if (series.dataLabelSettings.labelIntersectAction ==
        LabelIntersectAction.hide) {
      if (!_isCollide(rect, renderDataLabelRegions) &&
          (rect.left > containerRect.left &&
              rect.left + rect.width <
                  containerRect.left + containerRect.width) &&
          rect.top > containerRect.top &&
          rect.top + rect.height < containerRect.top + containerRect.height) {
        _drawLabel(
            rect,
            labelLocation,
            label,
            connectorPath,
            canvas,
            series,
            point,
            pointIndex,
            seriesIndex,
            chart,
            textStyle,
            renderDataLabelRegions,
            animateOpacity);
      }
    } else {
      _drawLabel(
          rect,
          labelLocation,
          label,
          connectorPath,
          canvas,
          series,
          point,
          pointIndex,
          seriesIndex,
          chart,
          textStyle,
          renderDataLabelRegions,
          animateOpacity);
    }
  } else {
    canvas.drawPath(
        connectorPath,
        Paint()
          ..color = connector.width <= 0
              ? Colors.transparent
              : connector.color.withOpacity(animateOpacity) ??
                  point.fill.withOpacity(animateOpacity)
          ..strokeWidth = connector.width
          ..style = PaintingStyle.stroke);
  }
}

void _drawLabel(
    Rect labelRect,
    Offset location,
    String label,
    Path connectorPath,
    Canvas canvas,
    CircularSeries<dynamic, dynamic> series,
    ChartPoint<dynamic> point,
    int pointIndex,
    int seriesIndex,
    SfCircularChart chart,
    ChartTextStyle textStyle,
    List<Rect> renderDataLabelRegions,
    double animateOpacity) {
  Paint rectPaint;
  final DataLabelSettings dataLabel = series.dataLabelSettings;
  final ConnectorLineSettings connector = dataLabel.connectorLineSettings;
  if (connectorPath != null) {
    canvas.drawPath(
        connectorPath,
        Paint()
          ..color = connector.width <= 0
              ? Colors.transparent
              : connector.color ?? point.fill.withOpacity(animateOpacity)
          ..strokeWidth = connector.width
          ..style = PaintingStyle.stroke);
  }

  if (dataLabel.builder == null) {
    final double strokeWidth = series._renderer.getDataLabelStrokeWidth(
        series, point, pointIndex, seriesIndex, dataLabel.borderWidth);
    final Color labelFill = series._renderer.getDataLabelColor(
        series,
        point,
        pointIndex,
        seriesIndex,
        dataLabel.color != null
            ? dataLabel.color
            : (dataLabel.useSeriesColor ? point.fill : dataLabel.color));
    final Color strokeColor = series._renderer.getDataLabelStrokeColor(
        series,
        point,
        pointIndex,
        seriesIndex,
        dataLabel.borderColor.withOpacity(dataLabel.opacity));
    if (strokeWidth != null && strokeWidth > 0) {
      rectPaint = Paint()
        ..color = strokeColor.withOpacity(
            (animateOpacity - (1 - dataLabel.opacity)) < 0
                ? 0
                : animateOpacity - (1 - dataLabel.opacity))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      _drawLabelRect(
          rectPaint,
          Rect.fromLTRB(
              labelRect.left, labelRect.top, labelRect.right, labelRect.bottom),
          dataLabel.borderRadius,
          canvas);
    }
    if (labelFill != null) {
      _drawLabelRect(
          Paint()
            ..color = labelFill.withOpacity(
                (animateOpacity - (1 - dataLabel.opacity)) < 0
                    ? 0
                    : animateOpacity - (1 - dataLabel.opacity))
            ..style = PaintingStyle.fill,
          Rect.fromLTRB(
              labelRect.left, labelRect.top, labelRect.right, labelRect.bottom),
          dataLabel.borderRadius,
          canvas);
    }
    textStyle.color = textStyle.color.withOpacity(animateOpacity);
    _drawText(canvas, label, location, textStyle, dataLabel.angle);
    renderDataLabelRegions.add(labelRect);
  }
}

void _drawLabelRect(
        Paint paint, Rect labelRect, double borderRadius, Canvas canvas) =>
    canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, Radius.circular(borderRadius)),
        paint);

void _findDataLabelPosition(ChartPoint<dynamic> point) =>
    point.dataLabelPosition = ((point.midAngle >= -90 && point.midAngle < 0) ||
            (point.midAngle >= 0 && point.midAngle < 90) ||
            (point.midAngle >= 270))
        ? Position.right
        : Position.left;
