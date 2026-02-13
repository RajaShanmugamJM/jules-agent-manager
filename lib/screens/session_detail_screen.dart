import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../models/activity.dart';
import '../providers/jules_provider.dart';

class SessionDetailScreen extends StatefulWidget {
  final Session session;
  const SessionDetailScreen({Key? key, required this.session})
    : super(key: key);

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late final Activity _noPlanActivity;

  @override
  void initState() {
    super.initState();
    _noPlanActivity = Activity(
      id: '',
      type: ActivityType.planning,
      description: 'No plan generated yet.',
      timestamp: DateTime.now(),
      metadata: {},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JulesProvider>().fetchActivities(widget.session.sessionId);
    });
  }

  Future<void> _approvePlan() async {
    try {
      await context.read<JulesProvider>().approvePlan(widget.session.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plan approved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving plan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JulesProvider>();
    final activities = provider.activities;

    // Try to find updated session, fallback to widget.session
    final session = provider.sessions.firstWhere(
      (s) => s.sessionId == widget.session.sessionId,
      orElse: () => widget.session,
    );

    // Find the latest plan
    final planActivity = provider.latestPlan ?? _noPlanActivity;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(session.prompt, overflow: TextOverflow.ellipsis),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Plan'),
              Tab(text: 'Activity Log'),
            ],
          ),
        ),
        body: provider.isLoading && activities.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildPlanView(planActivity),
                  _buildActivityList(activities),
                ],
              ),
        bottomNavigationBar: session.status == SessionStatus.waitingForApproval
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _approvePlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Approve Plan & Execute'),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPlanView(Activity planActivity) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan generated at ${DateFormat.yMMMd().add_jm().format(planActivity.timestamp)}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Divider(),
          Expanded(child: Markdown(data: planActivity.description)),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<Activity> activities) {
    if (activities.isEmpty) {
      return const Center(child: Text('No activity yet.'));
    }
    // Sort activities descending for list view? PRD says chronological.
    // Usually logs are newest at bottom or top.
    // If chronological (oldest first), then the last item is the latest.
    // Provider sorts by timestamp ascending.
    // So list view should display them in that order.

    return ListView.builder(
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return ListTile(
          leading: _getActivityIcon(activity.type),
          title: Text(activity.description),
          subtitle: Text(
            DateFormat.yMMMd().add_jm().format(activity.timestamp),
          ),
          isThreeLine: true,
        );
      },
    );
  }

  Widget _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.planning:
        return const Icon(Icons.map, color: Colors.blue);
      case ActivityType.execution:
        return const Icon(Icons.code, color: Colors.orange);
      case ActivityType.interaction:
        return const Icon(Icons.chat, color: Colors.purple);
      case ActivityType.results:
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }
}
