import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/generation_service.dart';
import '../services/model_service.dart';
import '../theme.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final TextEditingController promptCtrl = TextEditingController();
  final TextEditingController characterCtrl = TextEditingController();
  final TextEditingController seedCtrl = TextEditingController(text: '0');

  String? selectedModelId;
  int durationSec = 30;

  static const List<int> durationOptions = [5, 15, 30, 60, 120, 180, 300, 480, 600];

  @override
  void dispose() {
    promptCtrl.dispose();
    characterCtrl.dispose();
    seedCtrl.dispose();
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'Create video',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Describe your story. Short scenes are generated and stitched into one video.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.clayMuted,
              ),
        ),
        const SizedBox(height: 24),

        ClayCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prompt',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: promptCtrl,
                minLines: 3,
                maxLines: 6,
                enabled: !busy,
                decoration: const InputDecoration(
                  hintText: 'A friendly rabbit teaching numbers in a sunny garden…',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: characterCtrl,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Character (for consistency)',
                  hintText: 'Orange rabbit with blue scarf',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        ClayCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (ids.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedModelId,
                  decoration: const InputDecoration(labelText: 'Model'),
                  items: models.models
                      .map(
                        (m) => DropdownMenuItem<String>(
                          value: m.id,
                          child: Text(
                            models.isReady(m.id)
                                ? '${m.name} · Ready'
                                : '${m.name} · Download needed',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: busy
                      ? null
                      : (String? v) => setState(() => selectedModelId = v),
                ),
              const SizedBox(height: 16),
              Text(
                'Target length',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: durationOptions.map((sec) {
                  final selected = durationSec == sec;
                  final label = sec < 60
                      ? '${sec}s'
                      : '${sec ~/ 60}m${sec % 60 == 0 ? '' : ' ${sec % 60}s'}';
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: busy
                        ? null
                        : (_) => setState(() => durationSec = sec),
                    selectedColor: AppTheme.clayAccentSoft,
                    labelStyle: TextStyle(
                      color: selected ? AppTheme.clayAccent : AppTheme.clayText,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: selected
                            ? AppTheme.clayAccent
                            : AppTheme.clayBorder,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: seedCtrl,
                enabled: !busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seed (0 = random)',
                  helperText: 'Same seed + character keeps style more consistent',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final prompt = promptCtrl.text.trim();
                    if (prompt.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a prompt')),
                      );
                      return;
                    }
                    if (selectedModelId == null) return;
                    if (!models.isReady(selectedModelId!) &&
                        selectedModelId != 'demo-t2v') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Download this model first from the Models tab',
                          ),
                        ),
                      );
                      return;
                    }
                    final seed = int.tryParse(seedCtrl.text.trim()) ?? 0;
                    await gen.generate(
                      prompt: prompt,
                      modelId: selectedModelId!,
                      durationSec: durationSec,
                      seed: seed,
                      character: characterCtrl.text.trim(),
                    );
                  },
            icon: Icon(busy ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded),
            label: Text(busy ? 'Generating…' : 'Generate video'),
          ),
        ),

        if (gen.phase != GenPhase.idle) ...[
          const SizedBox(height: 24),
          ClayCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      gen.phase == GenPhase.done
                          ? Icons.check_circle_rounded
                          : gen.phase == GenPhase.failed
                              ? Icons.error_outline_rounded
                              : Icons.auto_awesome_rounded,
                      color: gen.phase == GenPhase.done
                          ? AppTheme.claySuccess
                          : AppTheme.clayAccent,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        gen.message ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: gen.phase == GenPhase.failed ? null : gen.progress,
                    minHeight: 8,
                    backgroundColor: AppTheme.clayAccentSoft,
                    color: AppTheme.clayAccent,
                  ),
                ),
                if (gen.sceneProgress != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    gen.sceneProgress!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (gen.resultNote != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    gen.resultNote!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
