// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to match your backend address:
  // - For Android emulator: http://10.0.2.2:5000
  // - For iOS simulator: http://127.0.0.1:5000
  // - For physical device: http://<YOUR_COMPUTER_IP>:5000
 // static const String baseUrl = "http://127.0.0.1:5000";
  static const String baseUrl = "http://10.232.57.152:5000";

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
