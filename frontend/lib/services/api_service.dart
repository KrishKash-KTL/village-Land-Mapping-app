import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/field_model.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator (maps to host's localhost)
  // Change to your PC's IP if testing on a real device e.g. "192.168.1.5"
  static String baseUrl = 'http://127.0.0.1:8000';

  static Future<List<FieldModel>> fetchAllFields() async {
    final res = await http.get(Uri.parse('$baseUrl/api/fields'));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => FieldModel.fromJson(j)).toList();
    }
    throw Exception('Failed to fetch fields: ${res.body}');
  }

  static Future<FieldModel> createField({
    required String name,
    required String ownerName,
    String? khasraNumber,
    required List<List<double>> coordinates,
  }) async {
    final body = {
      'name': name,
      'owner_name': ownerName,
      'khasra_number': khasraNumber,
      // coordinates expected as [lon, lat] by backend
      'coordinates': coordinates.map((p) => [p[1], p[0]]).toList(),
    };
    final res = await http.post(
      Uri.parse('$baseUrl/api/fields'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      return FieldModel.fromJson(jsonDecode(res.body)['field']);
    }
    throw Exception('Failed to create field: ${res.body}');
  }

  static Future<FieldModel> getFieldById(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/fields/$id'));
    if (res.statusCode == 200) return FieldModel.fromJson(jsonDecode(res.body));
    throw Exception('Field not found');
  }

  static Future<List<Map<String, dynamic>>> getNearbyFields(
      double lat, double lon,
      {double radiusM = 1000}) async {
    final uri = Uri.parse(
        '$baseUrl/api/fields/nearby?lat=$lat&lon=$lon&radius_m=$radiusM');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    throw Exception('Failed to get nearby fields');
  }

  static Future<Map<String, dynamic>> getFieldAtLocation(
      double lat, double lon) async {
    final uri =
        Uri.parse('$baseUrl/api/fields/containing?lat=$lat&lon=$lon');
    final res = await http.get(uri);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to check location');
  }

  static Future<bool> deleteField(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/fields/$id'));
    return res.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getGmapsPlotInfo(
      double lat, double lon) async {
    final uri =
        Uri.parse('$baseUrl/api/gmaps/plot-info?lat=$lat&lon=$lon');
    final res = await http.get(uri);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to get plot info');
  }
}
