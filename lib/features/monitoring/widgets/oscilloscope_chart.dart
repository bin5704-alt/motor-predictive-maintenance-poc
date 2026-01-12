import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OscilloscopeChart extends StatelessWidget {
  final List<double> data;
  final Color lineColor;

  const OscilloscopeChart({
    super.key,
    required this.data,
    this.lineColor = const Color(0xFF00E5FF), // Cyan neon default
  });

  @override
  Widget build(BuildContext context) {
    // Limit data points for performance if list is huge
    // For a typical 1000Hz sampling, showing 100-200 points gives a good "wave" look.
    final displayData = data.length > 500
        ? data.sublist(data.length - 500)
        : data;

    final spots = displayData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(
          show: false,
        ), // Hide axes for clean oscilloscope look
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.1),
            ),
          ),
        ],
        // Fixed Y range for stability, or remove for auto-scaling
        minY: -20,
        maxY: 20,
        minX: 0,
        maxX: spots.isEmpty ? 100 : spots.length.toDouble(),
        lineTouchData: const LineTouchData(
          enabled: false,
        ), // Disable touch for raw stream performance
      ),
      duration: Duration.zero, // Disable animation for real-time updates
    );
  }
}
