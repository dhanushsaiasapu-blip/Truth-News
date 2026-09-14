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
  return fallback();
}
