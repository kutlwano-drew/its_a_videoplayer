import 'package:flutter/widgets.dart';
import '../features/player/screens/player_screen.dart';

final RouteFactory appRouteFactory = (settings) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (_, __, ___) => const PlayerScreen(),
  );
};
