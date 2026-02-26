class MlMetrics {
  final int tp, fp, tn, fn;
  final double precision, recall, f1, accuracy;

  MlMetrics({
    required this.tp,
    required this.fp,
    required this.tn,
    required this.fn,
    required this.precision,
    required this.recall,
    required this.f1,
    required this.accuracy,
  });

  factory MlMetrics.fromJson(Map<String, dynamic> json) {
    return MlMetrics(
      tp: json["TP"] ?? 0,
      fp: json["FP"] ?? 0,
      tn: json["TN"] ?? 0,
      fn: json["FN"] ?? 0,
      precision: (json["precision"] as num?)?.toDouble() ?? 0.0,
      recall: (json["recall"] as num?)?.toDouble() ?? 0.0,
      f1: (json["f1_score"] as num?)?.toDouble() ?? 0.0,
      accuracy: (json["accuracy"] as num?)?.toDouble() ?? 0.0,
    );
  }
}
