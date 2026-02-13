import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if key exists (optional, usually secure fields don't pre-fill unless hidden)
    // We defer reading context to build or addPostFrameCallback if needed, but initState read is ok for initial value
    // However, context.read is not recommended in initState without listen: false (which is default for read)
    final auth = context.read<AuthProvider>();
    if (auth.apiKey != null) {
      _apiKeyController.text = auth.apiKey!;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await context.read<AuthProvider>().setApiKey(
          _apiKeyController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('API Key saved successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving key: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jules Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your Google Jules API Key to get started.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                  helperText: 'Retrieve from jules.google.com/settings',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your API Key';
                  }
                  return null;
                },
                obscureText: true, // Key is sensitive
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveKey,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
