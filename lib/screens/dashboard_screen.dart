import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/jules_provider.dart';
import '../providers/auth_provider.dart';
import '../models/session.dart';
import 'create_session_screen.dart';
import 'session_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JulesProvider>().fetchSessions();
    });
  }

  Future<void> _retrySession(Session session) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retrying session...')),
      );

      await context.read<JulesProvider>().createSession(
            session.sourceName,
            session.prompt,
            session.requirePlanApproval,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error retrying session: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JulesProvider>();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jules Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthProvider>().logout();
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Pending'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => context.read<JulesProvider>().fetchSessions(),
          child: provider.isLoading && provider.sessions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : provider.error != null && provider.sessions.isEmpty
                  ? Center(child: Text('Error: ${provider.error}'))
                  : TabBarView(
                      children: [
                        _buildSessionList(provider.sessions),
                        _buildSessionList(provider.sessions
                            .where((s) => s.status == SessionStatus.running)
                            .toList()),
                        _buildSessionList(provider.sessions
                            .where((s) => s.status == SessionStatus.completed)
                            .toList()),
                        _buildSessionList(provider.sessions
                            .where((s) =>
                                s.status == SessionStatus.waitingForApproval)
                            .toList()),
                      ],
                    ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateSessionScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSessionList(List<Session> sessions) {
    if (sessions.isEmpty) {
      return const Center(child: Text('No sessions found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionDetailScreen(session: session),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          session.prompt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(session.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.yMMMd()
                                .add_jm()
                                .format(session.createTime),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      if (session.status == SessionStatus.failed)
                        SizedBox(
                          height: 32,
                          child: TextButton.icon(
                            onPressed: () => _retrySession(session),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry'),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                      if (session.status == SessionStatus.waitingForApproval)
                         SizedBox(
                          height: 32,
                          child: OutlinedButton(
                             onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SessionDetailScreen(session: session),
                                  ),
                                );
                             },
                             child: const Text("Review"),
                             style: OutlinedButton.styleFrom(
                               padding: const EdgeInsets.symmetric(horizontal: 8),
                             )
                          ),
                         )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(SessionStatus status) {
    Color color;
    Color textColor = Colors.white;
    String label;
    switch (status) {
      case SessionStatus.running:
        color = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        label = 'Running';
        break;
      case SessionStatus.completed:
        color = Colors.green.shade100;
        textColor = Colors.green.shade900;
        label = 'Completed';
        break;
      case SessionStatus.failed:
        color = Colors.red.shade100;
        textColor = Colors.red.shade900;
        label = 'Failed';
        break;
      case SessionStatus.waitingForApproval:
        color = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        label = 'Pending';
        break;
      default:
        color = Colors.grey.shade100;
        textColor = Colors.grey.shade900;
        label = 'Unknown';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
