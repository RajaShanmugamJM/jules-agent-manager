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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JulesProvider>();

    return Scaffold(
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
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<JulesProvider>().fetchSessions(),
        child: provider.isLoading && provider.sessions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null && provider.sessions.isEmpty
            ? Center(child: Text('Error: ${provider.error}'))
            : provider.sessions.isEmpty
            ? const Center(child: Text('No sessions found. Create one!'))
            : ListView.builder(
                physics:
                    const AlwaysScrollableScrollPhysics(), // Ensure pull-to-refresh works even if empty
                itemCount: provider.sessions.length,
                itemBuilder: (context, index) {
                  final session = provider.sessions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(
                        session.prompt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${session.statusText} • ${DateFormat.yMMMd().add_jm().format(session.createTime)}',
                      ),
                      leading: _buildStatusIcon(session.status),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SessionDetailScreen(session: session),
                          ),
                        );
                      },
                    ),
                  );
                },
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
    );
  }

  Widget _buildStatusIcon(SessionStatus status) {
    switch (status) {
      case SessionStatus.running:
        return const Icon(Icons.play_circle_outline, color: Colors.blue);
      case SessionStatus.completed:
        return const Icon(Icons.check_circle_outline, color: Colors.green);
      case SessionStatus.failed:
        return const Icon(Icons.error_outline, color: Colors.red);
      case SessionStatus.waitingForApproval:
        return const Icon(Icons.pause_circle_outline, color: Colors.orange);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }
}
