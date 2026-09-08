import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Production Render Backend URL
  static const String baseUrl = "https://agro-backend-mgba.onrender.com";

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