import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/keys.dart';

class PexelService {
  static const String _baseUrl = 'https://api.pexels.com/v1/search';

  Future<String> fetchClinicalImage(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?query=$query isolated object white background&per_page=1'),
        headers: {'Authorization': ApiKeys.pexelsKey},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['photos'] != null && data['photos'].isNotEmpty) {
          return data['photos'][0]['src']['medium'];
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}