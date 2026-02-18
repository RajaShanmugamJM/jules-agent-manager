import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../models/session.dart';
import '../providers/jules_provider.dart';

class LiveLogsWidget extends StatefulWidget {
  final Session session;
  const LiveLogsWidget({Key? key, required this.session}) : super(key: key);

  @override
  State<LiveLogsWidget> createState() => _LiveLogsWidgetState();
}

class _LiveLogsWidgetState extends State<LiveLogsWidget> {
  // Timer for session duration
  Timer? _timer;
  Timer? _pollingTimer;
  Duration _duration = Duration.zero;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize duration based on createTime
    _duration = DateTime.now().difference(widget.session.createTime);

    // Start timer if running
    if (widget.session.status == SessionStatus.running) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _duration = DateTime.now().difference(widget.session.createTime);
            // Simulate progress (0 to 100%)
            if (_progress < 0.95) {
              _progress += 0.005;
            }
          });
        }
      });

      // Polling for new activities (simulating stream)
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          context
              .read<JulesProvider>()
              .fetchActivities(widget.session.sessionId, background: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JulesProvider>();
    final activities =
        provider.activities; // Assuming this list is updated by polling or manual refresh

    return Column(
      children: [
        // Header with Timer and Progress
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black87,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Session Duration',
                      style: TextStyle(color: Colors.white70)),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white24,
                  color: Colors.blueAccent),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlBtn(
                      Icons.pause, 'Pause', Colors.orange, () {}),
                  _buildControlBtn(
                      Icons.play_arrow, 'Resume', Colors.green, () {}),
                  _buildControlBtn(
                      Icons.stop, 'Terminate', Colors.red, () {}),
                ],
              )
            ],
          ),
        ),

        // Logs List
        Expanded(
          child: Container(
            color: Colors.black,
            child: activities.isEmpty
                ? const Center(
                    child: Text('No logs yet.',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      // Reverse index to show latest at bottom if we want terminal style,
                      // but usually ListView shows top-down.
                      // Let's assume activities are chronological.
                      final activity = activities[index];
                      return _buildLogLine(activity);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildLogLine(Activity activity) {
    Color color = Colors.white;
    String prefix = '[INFO]';

    // Heuristic for log level
    if (activity.description.toLowerCase().contains('error') ||
        activity.description.toLowerCase().contains('failed')) {
      color = Colors.redAccent;
      prefix = '[ERROR]';
    } else if (activity.description.toLowerCase().contains('warn')) {
      color = Colors.orangeAccent;
      prefix = '[WARN]';
    } else if (activity.type == ActivityType.execution) {
      color = Colors.lightBlueAccent;
      prefix = '[BUSY]';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          children: [
            TextSpan(
                text: '${_formatTime(activity.timestamp)} ',
                style: const TextStyle(color: Colors.grey)),
            TextSpan(
                text: '$prefix ',
                style:
                    TextStyle(color: color, fontWeight: FontWeight.bold)),
            TextSpan(
                text: activity.description,
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }
}
