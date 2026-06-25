import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000";

  static Future<Map<String, dynamic>> predictDisease(
      String imagePath) async {

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

    var responseBody =
        await response.stream.bytesToString();

    return jsonDecode(responseBody);
  }
}