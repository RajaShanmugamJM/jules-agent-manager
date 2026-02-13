import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jules_provider.dart';
import '../models/source.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({Key? key}) : super(key: key);

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSource;
  final _promptController = TextEditingController();
  bool _requirePlanApproval = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch sources if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<JulesProvider>();
      if (provider.sources.isEmpty) {
        provider.fetchSources();
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await context.read<JulesProvider>().createSession(
          _selectedSource!,
          _promptController.text,
          _requirePlanApproval,
        );
        if (mounted) {
          Navigator.pop(context); // Go back to dashboard
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating session: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JulesProvider>();
    final sources = provider.sources;

    return Scaffold(
      appBar: AppBar(title: const Text('New Session')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (provider.isLoading && sources.isEmpty)
                const LinearProgressIndicator(),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Error loading sources: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              DropdownButtonFormField<String>(
                value: _selectedSource,
                items: sources.map((Source source) {
                  return DropdownMenuItem<String>(
                    value: source.name,
                    child: Text(source.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedSource = value);
                },
                decoration: const InputDecoration(
                  labelText: 'Select Source (Repo)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Please select a source' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'Task Prompt',
                  hintText: 'Describe what you want Jules to do...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a prompt';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Require Plan Approval'),
                subtitle: const Text(
                  'Agent will wait for your approval before coding',
                ),
                value: _requirePlanApproval,
                onChanged: (val) => setState(() => _requirePlanApproval = val),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_isLoading || sources.isEmpty)
                    ? null
                    : _createSession,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Start Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
