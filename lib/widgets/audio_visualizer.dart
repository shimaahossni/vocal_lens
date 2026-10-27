import 'dart:math';
import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final bool isPaused;
  final Color activeColor;
  final double height;
  final int barCount;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.isPaused = false,
    this.activeColor = const Color(0xFF6366F1),
    this.height = 42,
    this.barCount = 24,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  late List<double> _targetHeights;
  late List<double> _currentHeights;

  @override
  void initState() {
    super.initState();
    _targetHeights = List.generate(widget.barCount, (i) => 0.15);
    _currentHeights = List.generate(widget.barCount, (i) => 0.15);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    )..addListener(() {
        if (widget.isPlaying && !widget.isPaused) {
          setState(() {
            for (int i = 0; i < widget.barCount; i++) {
              // Interpolate smoothly toward target
              _currentHeights[i] = _currentHeights[i] + (_targetHeights[i] - _currentHeights[i]) * 0.45;
            }
          });
        }
      });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.isPlaying && !widget.isPaused) {
          // Generate new targets with wave pattern
          for (int i = 0; i < widget.barCount; i++) {
            // Sine modulation + random jitter for lifelike voice wave
            final wave = (sin(i / widget.barCount * pi) * 0.8) + 0.2;
            _targetHeights[i] = (wave * (_random.nextDouble() * 0.7 + 0.3)).clamp(0.12, 1.0);
          }
          _controller.forward(from: 0.0);
        }
      }
    });

    if (widget.isPlaying) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.forward(from: 0.0);
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
      setState(() {
        for (int i = 0; i < widget.barCount; i++) {
          _currentHeights[i] = 0.15;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final idleColor = theme.colorScheme.onSurface.withOpacity(0.18);

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          final barFactor = widget.isPlaying && !widget.isPaused ? _currentHeights[index] : 0.15;
          final barHeight = (widget.height * barFactor).clamp(4.0, widget.height);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            width: 3.5,
            height: barHeight,
            decoration: BoxDecoration(
              gradient: widget.isPlaying && !widget.isPaused
                  ? LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        widget.activeColor.withOpacity(0.6),
                        widget.activeColor,
                      ],
                    )
                  : null,
              color: widget.isPlaying && !widget.isPaused ? null : idleColor,
              borderRadius: BorderRadius.circular(4.0),
            ),
          );
        }),
      ),
    );
  }
}
