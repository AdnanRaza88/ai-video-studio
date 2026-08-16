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
  final controller = TextEditingController();
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
    final ready = models.models.where((m) => models.isReady(m.id)).toList();
    selectedModelId ??= ready.isNotEmpty
        ? ready.first.id
        : (models.models.isNotEmpty ? models.models.first.id : null);

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
          'Write a prompt. Models download in the Models tab — then generate here.',
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
            hintText: 'A cute cartoon rabbit counting flowers in a sunny garden…',
            alignLabelWithHint: true,
            labelText: 'Prompt',
          ),
        ),
        const SizedBox(height: 16),
        Text('Model', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (models.models.isEmpty)
          const Text('No models in manifest.')
        else
          DropdownButtonFormField<String>(
            value: selectedModelId,
            items: models.models
                .map(
                  (m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(
                      '${m.name}${models.isReady(m.id) ? ' · Ready' : ' · Not downloaded'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => selectedModelId = v),
          ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: gen.phase == GenPhase.running ||
                  gen.phase == GenPhase.preparing
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
          icon: const Icon(Icons.play_arrow_rounded),
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
                  Text(
                    gen.message ?? '',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: gen.phase == GenPhase.failed ? 0 : gen.progress,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 8,
                  ),
                  if (gen.resultNote != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      gen.resultNote!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
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
