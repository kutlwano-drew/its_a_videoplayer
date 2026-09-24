import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoView extends StatelessWidget {
  const VideoView({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Video(controller: controller, controls: NoVideoControls);
  }
}
