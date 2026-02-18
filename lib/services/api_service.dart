import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/source.dart';
import '../models/session.dart';
import '../models/activity.dart';

class ApiService {
  final String apiKey;
  final String baseUrl = 'https://jules.googleapis.com';

  ApiService(this.apiKey);

  Map<String, String> get _headers => {
    'X-Goog-Api-Key': apiKey,
    'Content-Type': 'application/json',
  };

  Future<List<Source>> getSources() async {
    final response = await http.get(
      Uri.parse('$baseUrl/v1alpha/sources'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> sourcesJson = data['sources'] ?? [];
      return sourcesJson.map((json) => Source.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load sources: ${response.body}');
    }
  }

  Future<List<Session>> getSessions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/v1alpha/sessions'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> sessionsJson = data['sessions'] ?? [];
      return sessionsJson.map((json) => Session.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load sessions: ${response.body}');
    }
  }

  Future<Session> createSession(
    String sourceName,
    String prompt,
    bool requirePlanApproval,
  ) async {
    final body = json.encode({
      'source': sourceName,
      'prompt': prompt,
      'requirePlanApproval': requirePlanApproval,
    });
    final response = await http.post(
      Uri.parse('$baseUrl/v1alpha/sessions'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode == 200) {
      return Session.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create session: ${response.body}');
    }
  }

  Future<List<Activity>> getActivities(String sessionId) async {
    // We assume sessionId is the full resource name.
    // If it's not, we might need to adjust.
    // E.g. if sessionId is "projects/...", we append "/activities"
    final url = '$baseUrl/v1alpha/$sessionId/activities';

    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> activitiesJson = data['activities'] ?? [];
      return activitiesJson.map((json) => Activity.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load activities: ${response.body}');
    }
  }

  Future<void> approvePlan(String sessionId) async {
    final url = '$baseUrl/v1alpha/$sessionId:approvePlan';
    final response = await http.post(Uri.parse(url), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to approve plan: ${response.body}');
    }
  }

  Future<void> rejectPlan(String sessionId) async {
    final url = '$baseUrl/v1alpha/$sessionId:rejectPlan';
    final response = await http.post(Uri.parse(url), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to reject plan: ${response.body}');
    }
  }
}
