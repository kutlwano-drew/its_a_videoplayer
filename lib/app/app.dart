import 'package:flutter/material.dart';

import '../features/player/screens/player_screen.dart';
import 'theme.dart';

class ItsAVideoPlayerApp extends StatelessWidget {
  const ItsAVideoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'It\'s a Video Player',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const PlayerScreen(),
    );
  }
}
