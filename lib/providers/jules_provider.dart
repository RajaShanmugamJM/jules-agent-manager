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
  Activity? _latestPlan;
  bool _isLoading = false;
  String? _error;

  List<Session> get sessions => _sessions;
  List<Source> get sources => _sources;
  List<Activity> get activities => _activities;
  Activity? get latestPlan => _latestPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _updateLatestPlan() {
    try {
      _latestPlan = _activities.lastWhere(
        (a) => a.type == ActivityType.planning,
      );
    } catch (_) {
      _latestPlan = null;
    }
  }

  void updateApiService(ApiService? service) {
    _apiService = service;
    // Don't notify listeners here unless necessary to trigger rebuilds, but usually this is called during proxy update.
    // However, if service changes (e.g. login/logout), we might want to clear data.
    if (_apiService == null) {
      _sessions = [];
      _sources = [];
      _activities = [];
      _latestPlan = null;
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

  Future<void> fetchActivities(String sessionId,
      {bool background = false}) async {
    if (_apiService == null) return;
    if (!background) {
      _isLoading = true;
      _activities = [];
      _latestPlan = null;
      notifyListeners();
    }
    _error = null;

    try {
      final newActivities = await _apiService!.getActivities(sessionId);
      // Sort activities chronological? Usually they come chronological.
      // PRD says "chronological list".
      newActivities.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _activities = newActivities;
      _updateLatestPlan();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!background) {
        _isLoading = false;
      }
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

  Future<void> rejectPlan(String sessionId) async {
    if (_apiService == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _apiService!.rejectPlan(sessionId);
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
