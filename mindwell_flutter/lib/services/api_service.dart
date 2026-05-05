import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:5000';

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  static Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> delete(String path, [Map<String, dynamic>? body]) async {
    final req = http.Request('DELETE', Uri.parse('$baseUrl$path'));
    req.headers['Content-Type'] = 'application/json';
    if (body != null) req.body = jsonEncode(body);
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    try { return jsonDecode(res.body); } catch (_) { return {}; }
  }
}
