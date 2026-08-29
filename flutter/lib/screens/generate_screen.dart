import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/character_service.dart';
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
  final TextEditingController seedCtrl = TextEditingController(text: '0');
  final ImagePicker _picker = ImagePicker();

  String? selectedModelId;
  int durationSec = 30;

  static const List<int> durationOptions = [5, 15, 30, 60, 120, 180, 300, 480, 600];

  @override
  void dispose() {
    promptCtrl.dispose();
    seedCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCharacter(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.claySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add character photo', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final file = await _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 90);
    if (file == null || !context.mounted) return;

    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Name this character'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. Orange rabbit',
            labelText: 'Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final chars = context.read<CharacterService>();
    await chars.addFromFile(
      sourcePath: file.path,
      name: nameCtrl.text.trim().isEmpty ? 'Character' : nameCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final models = context.watch<ModelService>();
    final chars = context.watch<CharacterService>();
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
        Text('Create video', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Add character photos once. Every scene gets those same images so the model keeps them consistent.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.clayMuted),
        ),
        const SizedBox(height: 24),

        // —— Characters ——
        ClayCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Your characters', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : () => _addCharacter(context),
                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                    label: const Text('Add photo'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Selected photos are sent to the model on every scene.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              if (chars.characters.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.clayAccentSoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'No characters yet. Add a photo of your character so every scene stays consistent.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: chars.characters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final c = chars.characters[i];
                      final selected = chars.selectedIds.contains(c.id);
                      return GestureDetector(
                        onTap: busy ? null : () => chars.toggleSelected(c.id),
                        onLongPress: busy
                            ? null
                            : () async {
                                final del = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Remove ${c.name}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                                if (del == true) await chars.remove(c.id);
                              },
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: selected ? AppTheme.clayAccent : AppTheme.clayBorder,
                                  width: selected ? 2.5 : 1,
                                ),
                                image: File(c.imagePath).existsSync()
                                    ? DecorationImage(
                                        image: FileImage(File(c.imagePath)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: AppTheme.clayAccentSoft,
                              ),
                              child: selected
                                  ? Align(
                                      alignment: Alignment.topRight,
                                      child: Container(
                                        margin: const EdgeInsets.all(4),
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.clayAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 76,
                              child: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
              Text('Story prompt', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: promptCtrl,
                minLines: 3,
                maxLines: 6,
                enabled: !busy,
                decoration: const InputDecoration(
                  hintText: 'Rabbit teaches counting in a sunny garden…',
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
              Text('Settings', style: Theme.of(context).textTheme.titleMedium),
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
                  onChanged: busy ? null : (v) => setState(() => selectedModelId = v),
                ),
              const SizedBox(height: 16),
              Text('Target length', style: Theme.of(context).textTheme.bodySmall),
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
                    onSelected: busy ? null : (_) => setState(() => durationSec = sec),
                    selectedColor: AppTheme.clayAccentSoft,
                    labelStyle: TextStyle(
                      color: selected ? AppTheme.clayAccent : AppTheme.clayText,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: selected ? AppTheme.clayAccent : AppTheme.clayBorder,
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
                  helperText: 'Same seed + same character photos → more consistent style',
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
                    if (!models.isReady(selectedModelId!) && selectedModelId != 'demo-t2v') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Download this model first from the Models tab'),
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
                      characterRefs: chars.selectedPayload(),
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
                      child: Text(gen.message ?? '', style: Theme.of(context).textTheme.titleMedium),
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
                  Text(gen.sceneProgress!, style: Theme.of(context).textTheme.bodySmall),
                ],
                if (gen.resultNote != null) ...[
                  const SizedBox(height: 12),
                  Text(gen.resultNote!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
