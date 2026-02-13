enum SessionStatus { running, completed, failed, waitingForApproval, unknown }

class Session {
  final String sessionId; // The resource name
  final String prompt;
  final SessionStatus status;
  final DateTime createTime;
  final DateTime lastActivityTime;
  final bool requirePlanApproval;
  final String sourceName; // Reference to Source

  Session({
    required this.sessionId,
    required this.prompt,
    required this.status,
    required this.createTime,
    required this.lastActivityTime,
    required this.requirePlanApproval,
    required this.sourceName,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionId: json['name'] as String,
      prompt: json['prompt'] as String? ?? '',
      status: _parseStatus(
        json['state'] as String?,
      ), // Sometimes it's 'state', sometimes 'status'
      createTime:
          DateTime.tryParse(json['createTime'] as String? ?? '') ??
          DateTime.now(),
      lastActivityTime:
          DateTime.tryParse(json['updateTime'] as String? ?? '') ??
          DateTime.now(),
      requirePlanApproval: json['requirePlanApproval'] as bool? ?? false,
      sourceName: json['source'] as String? ?? '',
    );
  }

  static SessionStatus _parseStatus(String? status) {
    if (status == null) return SessionStatus.unknown;
    // Normalize to standard enum values
    switch (status.toUpperCase()) {
      case 'RUNNING':
      case 'EXECUTING':
      case 'PLANNING':
        return SessionStatus.running;
      case 'COMPLETED':
      case 'SUCCEEDED':
        return SessionStatus.completed;
      case 'FAILED':
        return SessionStatus.failed;
      case 'WAITING_FOR_APPROVAL':
      case 'PENDING_APPROVAL':
        return SessionStatus.waitingForApproval;
      default:
        return SessionStatus.unknown;
    }
  }

  String get statusText {
    switch (status) {
      case SessionStatus.running:
        return 'Running';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.failed:
        return 'Failed';
      case SessionStatus.waitingForApproval:
        return 'Waiting for Approval';
      default:
        return 'Unknown';
    }
  }
}
