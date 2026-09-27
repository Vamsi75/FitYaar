class BodyMeasurement {
  final int id;
  final DateTime date;
  final double? weightKg;
  final double? waistCm;
  final double? bodyFatPct;

  BodyMeasurement({
    required this.id,
    required this.date,
    this.weightKg,
    this.waistCm,
    this.bodyFatPct,
  });

  factory BodyMeasurement.fromJson(Map<String, dynamic> j) => BodyMeasurement(
        id: j['id'] as int,
        date: DateTime.parse(j['date'] as String),
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        waistCm: (j['waistCm'] as num?)?.toDouble(),
        bodyFatPct: (j['bodyFatPct'] as num?)?.toDouble(),
      );

  double? metric(BodyMetric m) => switch (m) {
        BodyMetric.weight => weightKg,
        BodyMetric.waist => waistCm,
        BodyMetric.bodyFat => bodyFatPct,
      };
}

enum BodyMetric { weight, waist, bodyFat }

String bodyMetricLabel(BodyMetric m) => switch (m) {
      BodyMetric.weight => 'Weight',
      BodyMetric.waist => 'Waist',
      BodyMetric.bodyFat => 'Body Fat',
    };

String bodyMetricUnit(BodyMetric m) => switch (m) {
      BodyMetric.weight => 'kg',
      BodyMetric.waist => 'cm',
      BodyMetric.bodyFat => '%',
    };
