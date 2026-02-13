enum ActivityType { planning, execution, interaction, results, unknown }

class Activity {
  final String id;
  final ActivityType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  Activity({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.metadata,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['name'] as String? ?? '', // ID might be 'name' in Google APIs
      type: _parseType(json['type'] as String?),
      description: json['description'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['createTime'] as String? ?? '') ??
          DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  static ActivityType _parseType(String? type) {
    if (type == null) return ActivityType.unknown;
    switch (type.toUpperCase()) {
      case 'PLANNING':
      case 'PLAN_GENERATION':
        return ActivityType.planning;
      case 'EXECUTION':
      case 'CODING':
      case 'TOOL_USE':
        return ActivityType.execution;
      case 'INTERACTION':
      case 'USER_INPUT':
        return ActivityType.interaction;
      case 'RESULTS':
      case 'OUTPUT':
      case 'COMPLETION':
        return ActivityType.results;
      default:
        return ActivityType.unknown;
    }
  }
}
