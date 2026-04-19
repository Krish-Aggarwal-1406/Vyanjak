import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String baseUrl = 'http://192.168.1.7:8000';

  Future<Map<String, dynamic>> predictWord(String audioPath, String contextDesc) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict'));
      request.fields['context'] = contextDesc;
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.body}');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }
}