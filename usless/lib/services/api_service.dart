
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl = "https://introvert-excuse-generator.onrender.com";

  static Future<Map<String, dynamic>> generateExcuse({
    required String context,
    required String category,
    required String tone,
    required String length,
    bool useAi = false,
  }) async {
    final uri = Uri.parse("$baseUrl/generate");
    final body = jsonEncode({
      "context": context,
      "category": category,
      "tone": tone,
      "length": length,
      "use_ai": useAi
    });

    final resp = await http.post(uri,
        headers: {"Content-Type": "application/json"}, body: body);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Server error: ${resp.statusCode} ${resp.body}");
    }
  }

  static Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse("$baseUrl/health");
      final resp = await http.get(uri);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
