import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/model_service.dart';

class ModelsScreen extends StatelessWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ModelService>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          'Models',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Download inside the app. After download, use them on the Create tab.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
        ),
        if (service.error != null) ...[
          const SizedBox(height: 12),
          Text(service.error!, style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 16),
        ...service.models.map((m) {
          final ready = service.isReady(m.id);
          final busy = service.downloading.contains(m.id);
          final progress = service.downloadProgress[m.id];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (m.recommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Recommended',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${m.sizeLabel} · ${m.license}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.black45,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (busy) ...[
                    LinearProgressIndicator(
                      value: progress,
                      borderRadius: BorderRadius.circular(8),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progress == null
                          ? 'Downloading…'
                          : 'Downloading ${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                    ),
                  ] else
                    Align(
                      alignment: Alignment.centerRight,
                      child: ready
                          ? FilledButton.tonal(
                              onPressed: null,
                              child: const Text('Ready'),
                            )
                          : FilledButton(
                              onPressed: m.downloadUrl == null
                                  ? null
                                  : () => service.download(m.id),
                              child: Text(
                                m.downloadUrl == null
                                    ? 'URL not set'
                                    : 'Download',
                              ),
                            ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
