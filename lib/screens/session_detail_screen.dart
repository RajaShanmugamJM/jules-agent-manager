import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../models/activity.dart';
import '../providers/jules_provider.dart';
import 'live_logs_widget.dart';

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

  Future<void> _rejectPlan() async {
    try {
      await context.read<JulesProvider>().rejectPlan(widget.session.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Plan rejected!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error rejecting plan: $e')));
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
                  LiveLogsWidget(session: session),
                ],
              ),
        bottomNavigationBar: session.status == SessionStatus.waitingForApproval
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  provider.isLoading ? null : _rejectPlan,
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Edit Plan not implemented')));
                              },
                              child: const Text('Edit Plan'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
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
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPlanView(Activity planActivity) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics
          Row(
            children: [
              _buildMetricCard('Est. Duration', '5m 30s', Icons.timer),
              const SizedBox(width: 16),
              _buildMetricCard('Files Impacted', '3', Icons.file_copy),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Plan generated at ${DateFormat.yMMMd().add_jm().format(planActivity.timestamp)}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Divider(),

          // Plan Content
          MarkdownBody(data: planActivity.description),

          const SizedBox(height: 24),
          const Text('Proposed Changes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),

          // Mock Diff Viewer
          _buildDiffViewer('lib/main.dart',
              '- return DashboardScreen();\n+ return MainScreen();'),
          _buildDiffViewer('lib/screens/dashboard.dart',
              '+ import \'package:flutter/material.dart\';'),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiffViewer(String filename, String diff) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title:
            Text(filename, style: const TextStyle(fontWeight: FontWeight.w600)),
        leading: const Icon(Icons.description, size: 20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Text(diff, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

}
