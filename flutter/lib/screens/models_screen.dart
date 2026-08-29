import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/model_service.dart';
import '../theme.dart';

class ModelsScreen extends StatelessWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ModelService>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'Models',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Download once. After that everything runs offline.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.clayMuted,
              ),
        ),
        if (service.error != null) ...[
          const SizedBox(height: 12),
          Text(
            service.error!,
            style: const TextStyle(color: Color(0xFFEF4444)),
          ),
        ],
        const SizedBox(height: 20),
        ...service.models.map((m) {
          final ready = service.isReady(m.id);
          final busy = service.downloading.contains(m.id);
          final progress = service.downloadProgress[m.id];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (m.recommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.clayAccentSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.clayAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${m.sizeLabel} · ${m.license}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.clayMuted,
                        ),
                  ),
                  const SizedBox(height: 14),
                  if (busy) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppTheme.clayAccentSoft,
                        color: AppTheme.clayAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progress == null
                          ? 'Downloading…'
                          : 'Downloading ${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else
                    Align(
                      alignment: Alignment.centerRight,
                      child: ready
                          ? FilledButton.tonal(
                              onPressed: null,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
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
