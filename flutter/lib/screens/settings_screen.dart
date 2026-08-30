import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController fal;
  late TextEditingController openai;
  late TextEditingController groq;
  late TextEditingController replicate;
  late TextEditingController customUrl;
  late TextEditingController customKey;
  late TextEditingController falModel;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsService>();
    fal = TextEditingController(text: s.falKey);
    openai = TextEditingController(text: s.openaiKey);
    groq = TextEditingController(text: s.groqKey);
    replicate = TextEditingController(text: s.replicateKey);
    customUrl = TextEditingController(text: s.customBaseUrl);
    customKey = TextEditingController(text: s.customApiKey);
    falModel = TextEditingController(text: s.falVideoModel);
  }

  @override
  void dispose() {
    fal.dispose();
    openai.dispose();
    groq.dispose();
    replicate.dispose();
    customUrl.dispose();
    customKey.dispose();
    falModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'API keys stay on your phone. Never uploaded to our servers.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.clayMuted),
        ),
        const SizedBox(height: 20),

        ClayCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Video provider', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: s.videoProvider,
                decoration: const InputDecoration(labelText: 'Provider'),
                items: const [
                  DropdownMenuItem(value: 'local', child: Text('Local (script only)')),
                  DropdownMenuItem(value: 'fal', child: Text('fal.ai (Seedance / Veo / Omni)')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom HTTP endpoint')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    s.videoProvider = v;
                    s.save();
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fal,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'fal.ai API key',
                  helperText: 'FAL_KEY — Seedance, Veo 3.1, Gemini Omni on fal',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: falModel,
                decoration: const InputDecoration(
                  labelText: 'fal model id',
                  helperText: 'e.g. bytedance/seedance-2.0/text-to-video or fal-ai/veo3.1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: customUrl,
                decoration: const InputDecoration(labelText: 'Custom base URL'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: customKey,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Custom API key'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        ClayCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Script agent (LLM)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: s.scriptProvider,
                decoration: const InputDecoration(labelText: 'Script provider'),
                items: const [
                  DropdownMenuItem(value: 'local_rule', child: Text('Built-in planner (free)')),
                  DropdownMenuItem(value: 'groq', child: Text('Groq (fast LLM)')),
                  DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    s.scriptProvider = v;
                    s.save();
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: groq,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Groq API key'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: openai,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'OpenAI API key'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              s.falKey = fal.text;
              s.openaiKey = openai.text;
              s.groqKey = groq.text;
              s.replicateKey = replicate.text;
              s.customBaseUrl = customUrl.text;
              s.customApiKey = customKey.text;
              s.falVideoModel = falModel.text;
              await s.save();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved on device')),
                );
              }
            },
            child: const Text('Save settings'),
          ),
        ),
      ],
    );
  }
}
