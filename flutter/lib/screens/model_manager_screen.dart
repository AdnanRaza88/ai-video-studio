import 'package:flutter/material.dart';

class ModelManagerScreen extends StatelessWidget {
  const ModelManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Models'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Models are downloaded to the device and never leave it.\nAfter download the app works offline.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _section(context, 'LLM (Story / Rhyme)', [
            'Small quantized models recommended for most devices.',
            'Download only after capability check (RAM / storage).',
          ]),
          _section(context, 'Image', [
            'Cartoon-oriented image generation models.',
          ]),
          _section(context, 'Video', [
            'Lightweight image-to-video or heavily optimized models only.',
            'High-end devices only for usable speed.',
          ]),
          _section(context, 'Audio / TTS', [
            'Open TTS voices suitable for children\'s content.',
          ]),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Model Manager is a placeholder. Real download, checksum verification, device capability detection and license display will be implemented with the native Model Manager service.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<String> points) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...points.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(p)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
