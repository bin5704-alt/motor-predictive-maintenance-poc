import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/app_text.dart';
import 'providers/monitoring_providers.dart';
import 'widgets/oscilloscope_chart.dart';
import 'widgets/spectrum_chart.dart';

class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  int _selectedSegment = 0; // 0: Time, 1: Frequency
  final List<double> _displayBuffer = [];

  @override
  Widget build(BuildContext context) {
    final sensorDataAsync = ref.watch(sensorDataStreamProvider);

    // Accumulate data for display buffer
    sensorDataAsync.whenData((chunk) {
      if (_displayBuffer.length > 2048) {
        _displayBuffer.removeRange(0, chunk.length);
      }
      _displayBuffer.addAll(chunk);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Navy Background
      appBar: AppBar(
        title: const AppText(
          'Real-time Precision Analysis',
          size: AppTextSize.lg,
          weight: FontWeight.bold,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Control Panel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildSegmentButton(0, 'Time Domain', Icons.show_chart),
                  _buildSegmentButton(1, 'Freq. Spectrum', Icons.bar_chart),
                ],
              ),
            ),
          ),

          // 2. Chart Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Grid background? (Handled in charts)

                      // Chart Content
                      sensorDataAsync.when(
                        data: (_) {
                          // Using local buffer for smooth rendering rather than just last chunk
                          if (_displayBuffer.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _selectedSegment == 0
                                ? OscilloscopeChart(data: _displayBuffer)
                                : SpectrumChart(
                                    data: _displayBuffer,
                                    samplingRate: 1000,
                                  ),
                          );
                        },
                        error: (err, stack) => Center(
                          child: Text(
                            'Error: $err',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                      ),

                      // Overlay Info
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: Colors.greenAccent,
                                size: 10,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Status Footer
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusItem('Sampling Rate', '1000 Hz'),
                _buildStatusItem('Buffer', '${_displayBuffer.length} pts'),
                _buildStatusItem('Upload Status', 'Active'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label, IconData icon) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB)
                : Colors.transparent, // Blue vs Transparent
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
