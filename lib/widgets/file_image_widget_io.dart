import 'dart:io';

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
  return Image.file(
    File(path),
    height: height,
    width: width,
    fit: fit,
    color: color,
    semanticLabel: semanticLabel,
    errorBuilder: (_, __, ___) => fallback(),
  );
}
