import 'package:flutter/material.dart';
import '../models/project.dart';

class ProjectEditorScreen extends StatefulWidget {
  final Project project;

  const ProjectEditorScreen({super.key, required this.project});

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Chat'),
            Tab(text: 'Story'),
            Tab(text: 'Characters'),
            Tab(text: 'Scenes'),
            Tab(text: 'Audio'),
            Tab(text: 'Preview'),
            Tab(text: 'Export'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _placeholder('Chat', 'Describe your rhyme or story. Context is managed locally.'),
          _placeholder('Story', 'Generated title, rhyme and scene structure will appear here.'),
          _placeholder('Characters', 'Create and edit characters with appearance and reference images.'),
          _placeholder('Scenes', 'Storyboard, visual prompts and per-scene generation.'),
          _placeholder('Audio', 'TTS voice and background music.'),
          _placeholder('Preview', 'Preview composed video.'),
          _placeholder('Export', 'Export final MP4 to device gallery.'),
        ],
      ),
    );
  }

  Widget _placeholder(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Native AI runtime integration pending.\nThis tab is wired for the local-first pipeline.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
