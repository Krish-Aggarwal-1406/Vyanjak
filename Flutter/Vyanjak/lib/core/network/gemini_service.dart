import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String baseUrl = 'https://vyanjak-backend.onrender.com';

  Future<Map<String, dynamic>> predictWord(
      String audioPath, String contextDesc) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/predict'));
      request.fields['context'] = contextDesc;
      request.files
          .add(await http.MultipartFile.fromPath('audio', audioPath));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('Timed out — try again.');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}