double? getAspectRatioFromDimensions(String? dimensions) {
  if (dimensions == null) return null;
  final parts = dimensions.split('x');
  if (parts.length != 2) return null;
  final w = double.tryParse(parts[0]);
  final h = double.tryParse(parts[1]);
  if (w == null || h == null || w <= 0 || h <= 0) return null;
  return w / h;
}
