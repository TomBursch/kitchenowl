class RecipeImportResult {
  final int detected;
  final int imported;
  final int skipped;
  final int failed;
  final bool complete;

  const RecipeImportResult({
    required this.detected,
    required this.imported,
    required this.skipped,
    required this.failed,
    required this.complete,
  });

  int get total => imported + skipped + failed;

  factory RecipeImportResult.fromJson(Map<String, dynamic> json) {
    return RecipeImportResult(
      detected: (json['detected'] as num?)?.toInt() ?? 0,
      imported: (json['imported'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      complete: json['complete'] as bool? ?? false,
    );
  }
}