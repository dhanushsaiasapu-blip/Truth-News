import 'file_image_widget_stub.dart'
    if (dart.library.io) 'file_image_widget_io.dart' as platform;

import 'package:flutter/material.dart';

Widget buildFileImage({
  required String path,
  double? height,
  double? width,
  BoxFit fit = BoxFit.cover,
  Color? color,
  String? semanticLabel,
  required Widget Function() fallback,
}) {
  return platform.buildFileImage(
    path: path,
    height: height,
    width: width,
    fit: fit,
    color: color,
    semanticLabel: semanticLabel,
    fallback: fallback,
  );
}
