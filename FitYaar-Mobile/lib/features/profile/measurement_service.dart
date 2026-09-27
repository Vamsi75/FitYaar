import '../../core/network/api_client.dart';
import 'measurement_models.dart';

/// Wraps /api/measurements (body weight / waist / body-fat over time).
class MeasurementService {
  final ApiClient _api;
  MeasurementService(this._api);

  Future<List<BodyMeasurement>> list() async {
    final list = await _api.get('/measurements') as List<dynamic>;
    return list
        .map((e) => BodyMeasurement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BodyMeasurement> upsert({
    DateTime? date,
    double? weightKg,
    double? waistCm,
    double? bodyFatPct,
  }) async {
    final body = <String, dynamic>{
      if (date != null) 'date': date.toIso8601String().split('T').first,
      'weightKg': weightKg,
      'waistCm': waistCm,
      'bodyFatPct': bodyFatPct,
    };
    final json = await _api.post('/measurements', body: body) as Map<String, dynamic>;
    return BodyMeasurement.fromJson(json);
  }

  Future<void> delete(int id) async => _api.delete('/measurements/$id');
}
