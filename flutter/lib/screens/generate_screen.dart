import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/character_service.dart';
import '../services/generation_service.dart';
import '../services/settings_service.dart';
import '../theme.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final ideaCtrl = TextEditingController();
  final seedCtrl = TextEditingController(text: '0');
  final picker = ImagePicker();
  int durationSec = 30;

  static const durations = [15, 30, 60, 120, 180, 300];

  @override
  void dispose() {
    ideaCtrl.dispose();
    seedCtrl.dispose();
    super.dispose();
  }

  Future<void> _addChar(BuildContext context) async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.claySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (src == null || !context.mounted) return;
    final f = await picker.pickImage(source: src, maxWidth: 1024, imageQuality: 90);
    if (f == null || !context.mounted) return;
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Character name'),
        content: TextField(controller: name, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<CharacterService>().addFromFile(
            sourcePath: f.path,
            name: name.text.trim().isEmpty ? 'Character' : name.text.trim(),
          );
    }
  }

  bool get _busy {
    final p = context.watch<GenerationService>().phase;
    return p != GenPhase.idle && p != GenPhase.done && p != GenPhase.failed;
  }

  @override
  Widget build(BuildContext context) {
    final chars = context.watch<CharacterService>();
    final gen = context.watch<GenerationService>();
    final settings = context.watch<SettingsService>();
    final busy = gen.phase != GenPhase.idle &&
        gen.phase != GenPhase.done &&
        gen.phase != GenPhase.failed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Text('Studio', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Idea → script agent → scenes → provider clips. Provider: ${settings.videoProvider}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),

        // Pipeline steps
        ClayCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _step(context, '1 Script', gen.phase.index >= GenPhase.writingScript.index),
              _line(),
              _step(context, '2 Scenes', gen.phase.index >= GenPhase.planningScenes.index),
              _line(),
              _step(context, '3 Clips', gen.phase.index >= GenPhase.generatingClips.index),
              _line(),
              _step(context, '4 Done', gen.phase == GenPhase.done),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ClayCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Characters', style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(
                    onPressed: busy ? null : () => _addChar(context),
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (chars.characters.isEmpty)
                Text(
                  'Add reference photos — used for consistency in prompts (and I2V when provider supports).',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: chars.characters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final c = chars.characters[i];
                      final sel = chars.selectedIds.contains(c.id);
                      return GestureDetector(
                        onTap: () => chars.toggleSelected(c.id),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: sel ? AppTheme.clayAccent : AppTheme.clayBorder,
                                  width: sel ? 2 : 1,
                                ),
                                image: File(c.imagePath).existsSync()
                                    ? DecorationImage(
                                        image: FileImage(File(c.imagePath)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                            Text(c.name, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        ClayCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your idea', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextField(
                controller: ideaCtrl,
                minLines: 3,
                maxLines: 6,
                enabled: !busy,
                decoration: const InputDecoration(
                  hintText: 'Rabbit teaches counting 1–10 in a garden…',
                ),
              ),
              const SizedBox(height: 12),
              Text('Length', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: durations.map((d) {
                  final sel = durationSec == d;
                  return ChoiceChip(
                    label: Text(d < 60 ? '${d}s' : '${d ~/ 60}m'),
                    selected: sel,
                    onSelected: busy ? null : (_) => setState(() => durationSec = d),
                    selectedColor: AppTheme.clayAccentSoft,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: seedCtrl,
                enabled: !busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Seed (0 = random)'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final idea = ideaCtrl.text.trim();
                    if (idea.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Write an idea first')),
                      );
                      return;
                    }
                    if (settings.videoProvider == 'fal' && !settings.hasFal) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('fal selected but no API key — open Settings'),
                        ),
                      );
                    }
                    await gen.run(
                      idea: idea,
                      durationSec: durationSec,
                      seed: int.tryParse(seedCtrl.text) ?? 0,
                      characterNames: chars.selected.map((c) => c.name).toList(),
                      characterImagePath:
                          chars.selected.isEmpty ? null : chars.selected.first.imagePath,
                      settings: settings,
                    );
                  },
            icon: Icon(busy ? Icons.hourglass_top : Icons.auto_awesome),
            label: Text(busy ? 'Running agent…' : 'Generate'),
          ),
        ),

        if (gen.phase != GenPhase.idle) ...[
          const SizedBox(height: 20),
          ClayCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gen.message ?? '', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: gen.phase == GenPhase.failed ? null : gen.progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.clayAccent,
                  backgroundColor: AppTheme.clayAccentSoft,
                ),
                if (gen.detail != null) ...[
                  const SizedBox(height: 10),
                  Text(gen.detail!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],

        if (gen.script != null) ...[
          const SizedBox(height: 16),
          ClayCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Script', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(gen.script!.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  gen.script!.fullScript,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Scenes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...gen.script!.scenes.map((sc) {
            final clip = gen.clips.where((c) => c.index == sc.index).toList();
            final st = clip.isEmpty ? 'pending' : clip.first.status;
            final url = clip.isEmpty ? null : clip.first.videoUrl;
            final err = clip.isEmpty ? null : clip.first.error;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClayCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${sc.index + 1}. ${sc.title}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.clayAccentSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(st, style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(sc.visualPrompt, style: Theme.of(context).textTheme.bodySmall),
                    if (url != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => launchUrl(Uri.parse(url)),
                        child: const Text('Open video'),
                      ),
                    ],
                    if (err != null && st != 'ready') ...[
                      const SizedBox(height: 4),
                      Text(err, style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _step(BuildContext context, String label, bool on) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            on ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: on ? AppTheme.clayAccent : AppTheme.clayMuted,
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: on ? AppTheme.clayText : AppTheme.clayMuted)),
        ],
      ),
    );
  }

  Widget _line() => Container(width: 12, height: 1, color: AppTheme.clayBorder);
}
