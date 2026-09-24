import 'package:flutter/material.dart';

class VolumeControl extends StatelessWidget {
  const VolumeControl({super.key, required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Slider(
        value: value.clamp(0.0, 1.0).toDouble(),
        min: 0,
        max: 1,
        onChanged: onChanged,
      );
}
