import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/session.dart';
import '../models/source.dart';
import '../models/activity.dart';

class JulesProvider with ChangeNotifier {
  ApiService? _apiService;

  List<Session> _sessions = [];
  List<Source> _sources = [];
  List<Activity> _activities = [];
  bool _isLoading = false;
  String? _error;

  List<Session> get sessions => _sessions;
  List<Source> get sources => _sources;
  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateApiService(ApiService? service) {
    _apiService = service;
    // Don't notify listeners here unless necessary to trigger rebuilds, but usually this is called during proxy update.
    // However, if service changes (e.g. login/logout), we might want to clear data.
    if (_apiService == null) {
      _sessions = [];
      _sources = [];
      _activities = [];
    }
    notifyListeners();
  }

  Future<void> fetchSessions() async {
    if (_apiService == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _sessions = await _apiService!.getSessions();
      // Sort sessions by createTime descending (newest first)
      _sessions.sort((a, b) => b.createTime.compareTo(a.createTime));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSources() async {
    if (_apiService == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _sources = await _apiService!.getSources();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createSession(
    String sourceName,
    String prompt,
    bool requirePlanApproval,
  ) async {
    if (_apiService == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _apiService!.createSession(sourceName, prompt, requirePlanApproval);
      await fetchSessions();
    } catch (e) {
      _error = e.toString();
      rethrow; // Allow UI to handle specific error or show toast
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActivities(String sessionId) async {
    if (_apiService == null) return;
    _isLoading = true;
    _error = null;
    _activities = [];
    notifyListeners();
    try {
      _activities = await _apiService!.getActivities(sessionId);
      // Sort activities chronological? Usually they come chronological.
      // PRD says "chronological list".
      _activities.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approvePlan(String sessionId) async {
    if (_apiService == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _apiService!.approvePlan(sessionId);
      await fetchActivities(sessionId);
      await fetchSessions();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
