class ABLoopState {
  const ABLoopState({this.a, this.b});

  final Duration? a;
  final Duration? b;

  bool get active => a != null && b != null;
}
