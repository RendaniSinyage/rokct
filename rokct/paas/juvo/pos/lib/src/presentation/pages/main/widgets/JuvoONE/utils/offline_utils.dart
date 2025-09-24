import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const String offlineRequestsKey = 'offlineRequests';

Future<void> saveOfflineRequest(String url, String method, Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  final offlineRequests = jsonDecode(prefs.getString(offlineRequestsKey) ?? '[]') as List;
  offlineRequests.add({
    'url': url,
    'method': method,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  await prefs.setString(offlineRequestsKey, jsonEncode(offlineRequests));
}

Future<List<Map<String, dynamic>>> getOfflineRequests() async {
  final prefs = await SharedPreferences.getInstance();
  final offlineRequests = jsonDecode(prefs.getString(offlineRequestsKey) ?? '[]') as List;
  return offlineRequests.cast<Map<String, dynamic>>();
}

Future<void> clearOfflineRequest(int index) async {
  final prefs = await SharedPreferences.getInstance();
  final offlineRequests = await getOfflineRequests();
  offlineRequests.removeAt(index);
  await prefs.setString(offlineRequestsKey, jsonEncode(offlineRequests));
}

Future<void> processOfflineRequests() async {
  final offlineRequests = await getOfflineRequests();
  for (int i = 0; i < offlineRequests.length; i++) {
    final request = offlineRequests[i];
    final url = request['url'];
    final method = request['method'];
    final data = request['data'];

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await getToken()}',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        await clearOfflineRequest(i);
        i--; // Adjust index after removal
      } else {
        throw Exception('Failed to process offline request');
      }
    } catch (error) {
      print('Error processing offline request: $error');
      // Keep the request in the queue to retry later
    }
  }
}

Future<String> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token') ?? '';
}
