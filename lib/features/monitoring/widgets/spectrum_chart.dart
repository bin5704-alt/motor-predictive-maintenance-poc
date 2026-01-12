import 'dart:math';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SpectrumChart extends StatefulWidget {
  final List<double> data;
  final int samplingRate;
  final Color barColor;
  final List<RangeValues>?
  highlights; // Start-End Frequency ranges to highlight

  const SpectrumChart({
    super.key,
    required this.data,
    required this.samplingRate,
    this.barColor = const Color(0xFFC6FF00), // Lime neon default
    this.highlights,
  });

  @override
  State<SpectrumChart> createState() => _SpectrumChartState();
}

class _SpectrumChartState extends State<SpectrumChart> {
  // Zoom state
  double _minX = 0;
  double _maxX = 0;
  // Initial max frequency (Nyquist)
  double get _maxFreq => widget.samplingRate / 2;

  @override
  void initState() {
    super.initState();
    _maxX = _maxFreq;
  }

  @override
  void didUpdateWidget(covariant SpectrumChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.samplingRate != widget.samplingRate) {
      _maxX = _maxFreq; // Reset zoom if sampling rate changes fundamentally
    }
  }

  @override
  Widget build(BuildContext context) {
    final fftData = _calculateFFT(widget.data, widget.samplingRate);

    // Create spots from FFT data
    // fftData is structured as [Frequency, Magnitude]
    final spots = fftData.map((e) => FlSpot(e.key, e.value)).toList();

    return GestureDetector(
      onScaleStart: (details) {
        // Optional: Capture start state if needed for precise relative zooming
      },
      onScaleUpdate: (details) {
        setState(() {
          // Simple zoom logic centered on the current view
          // Scale > 1 : Zoom In (Should decrease range)
          // Scale < 1 : Zoom Out (Should increase range)

          final currentRange = _maxX - _minX;
          final newRange = currentRange / details.scale;

          // We apply the zoom around the focal point, but for simplicity here
          // we just contract/expand the edges. A robust implementation would
          // use details.focalPoint to anchor the zoom.

          // Clamping to valid ranges
          if (newRange > 10 && newRange <= _maxFreq) {
            final center = _minX + currentRange / 2;
            _minX = max(0, center - newRange / 2);
            _maxX = min(_maxFreq, center + newRange / 2);
          }
        });
      },
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10),
            getDrawingVerticalLine: (_) => FlLine(color: Colors.white10),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (_maxX - _minX) / 5, // Dynamic interval based on zoom
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${value.toInt()} Hz',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ), // Hide Magnitude values for cleaner UI
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.white24),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: widget.barColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: widget.barColor.withValues(alpha: 0.2),
              ),
            ),
          ],
          rangeAnnotations: widget.highlights != null
              ? RangeAnnotations(
                  verticalRangeAnnotations: widget.highlights!
                      .map(
                        (range) => VerticalRangeAnnotation(
                          x1: range.start,
                          x2: range.end,
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      )
                      .toList(),
                )
              : null,
          minX: _minX,
          maxX: _maxX,
          minY: 0,
          // maxY: Auto-calculated by chart, or we can fix it if normalization is consistent
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.x.toStringAsFixed(1)} Hz\n${spot.y.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
        duration: const Duration(
          milliseconds: 0,
        ), // Disable animation for performance
      ),
    );
  }

  List<MapEntry<double, double>> _calculateFFT(
    List<double> rawData,
    int samplingRate,
  ) {
    if (rawData.isEmpty) return [];

    final n = rawData.length;
    final p = (log(n) / log(2)).ceil();
    final paddedSize = pow(2, p).toInt();

    // Explicitly typed as Float64List (standard doubles) for input
    final Float64List paddedData = Float64List(paddedSize);
    for (int i = 0; i < n; i++) {
      paddedData[i] = rawData[i];
    }

    final fft = FFT(paddedSize);
    final freqData = fft.realFft(paddedData);

    final List<MapEntry<double, double>> spectrum = [];

    // freqData is likely Float64x2List (Complex: x=Real, y=Imaginary)
    for (int i = 1; i < paddedSize ~/ 2; i++) {
      final frequency = i * samplingRate / paddedSize;

      // Manually calculate magnitude from Complex number
      final complex = freqData[i];
      final magnitude = sqrt(complex.x * complex.x + complex.y * complex.y);

      spectrum.add(MapEntry(frequency, magnitude));
    }

    return spectrum;
  }
}
