import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android Emulator, or localhost / LAN IP for physical device / web
  static const String baseUrl = "http://10.0.2.2:8000";

  static Future<Map<String, dynamic>> predictDisease(String imagePath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imagePath,
      ),
    );

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    return jsonDecode(responseBody);
  }

  static Future<Map<String, dynamic>> recommendCrop(Map<String, dynamic> params) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommend_crop'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(params),
    );

    return jsonDecode(response.body);
  }
}