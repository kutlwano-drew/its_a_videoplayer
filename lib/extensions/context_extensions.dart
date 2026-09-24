import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;
  bool get isCompact => width < 900;
}
