class EvalRow {
  final int lotId;
  final int itemId;
  final String itemName;
  final String baselineStatus;
  final List<String> baselineReasons;
  final bool? mlIsAnomaly;
  final double? mlScore;
  final List<String>? mlSignals;

  EvalRow({
    required this.lotId,
    required this.itemId,
    required this.itemName,
    required this.baselineStatus,
    required this.baselineReasons,
    this.mlIsAnomaly,
    this.mlScore,
    this.mlSignals,
  });

  factory EvalRow.fromJson(Map<String, dynamic> json) {
    return EvalRow(
      lotId: json["lot_id"],
      itemId: json["item_id"],
      itemName: json["item_name"] ?? "",
      baselineStatus: (json["baseline_status"] ?? "").toString(),
      baselineReasons:
          (json["baseline_reasons"] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      mlIsAnomaly: json["ml_is_anomaly"] as bool?,
      mlScore:
          json["ml_score"] == null
              ? null
              : (json["ml_score"] as num).toDouble(),
      mlSignals:
          (json["ml_signals"] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
    );
  }
}
