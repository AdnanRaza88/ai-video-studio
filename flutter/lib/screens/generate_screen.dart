import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/generation_service.dart';
import '../services/model_service.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final TextEditingController controller = TextEditingController();
  String? selectedModelId;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final models = context.watch<ModelService>();
    final gen = context.watch<GenerationService>();

    final ids = models.models.map((m) => m.id).toList();
    if (selectedModelId == null || !ids.contains(selectedModelId)) {
      selectedModelId = ids.isNotEmpty ? ids.first : null;
    }

    final busy =
        gen.phase == GenPhase.running || gen.phase == GenPhase.preparing;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          'AI Video Studio',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Write a prompt. Download models from the Models tab first.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Prompt',
            hintText: 'A cute cartoon rabbit counting flowers…',
          ),
        ),
        const SizedBox(height: 16),
        if (ids.isNotEmpty)
          DropdownButtonFormField<String>(
            value: selectedModelId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Model',
            ),
            items: models.models
                .map(
                  (m) => DropdownMenuItem<String>(
                    value: m.id,
                    child: Text(
                      models.isReady(m.id)
                          ? '${m.name} (Ready)'
                          : '${m.name} (Not downloaded)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: busy
                ? null
                : (String? v) {
                    setState(() => selectedModelId = v);
                  },
          ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: busy
              ? null
              : () async {
                  final prompt = controller.text.trim();
                  if (prompt.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a prompt')),
                    );
                    return;
                  }
                  if (selectedModelId == null) return;
                  if (!models.isReady(selectedModelId!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Download this model first from the Models tab',
                        ),
                      ),
                    );
                    return;
                  }
                  await gen.generate(
                    prompt: prompt,
                    modelId: selectedModelId!,
                  );
                },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Generate video'),
        ),
        if (gen.phase != GenPhase.idle) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gen.message ?? ''),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: gen.phase == GenPhase.failed ? null : gen.progress,
                  ),
                  if (gen.resultNote != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      gen.resultNote!,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
