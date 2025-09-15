import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../providers/note_provider.dart';
import '../../models/models.dart';
import 'note_form_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final int noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Note? _note;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNote();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadNote() async{
    final note = await context.read<NoteProvider>().getNoteDetails(widget.noteId);
    setState(() {
      _note = note;
    });
  }

  Future<void> _shareNote() async {
    if (_note == null) return;
    
    String content = 'Note: ${_note!.title}\\n';
    content += 'Course: ${_note!.courseTitle}\\n\\n';
    
    if (_note!.keyPoints.isNotEmpty) {
      content += 'Key Points:\\n';
      for (int i = 0; i < _note!.keyPoints.length; i++) {
        content += '${i + 1}. ${_note!.keyPoints[i]}\\n';
      }
      content += '\\n';
    }
    
    if (_note!.detailedNotes.isNotEmpty) {
      content += 'Detailed Notes:\\n${_note!.detailedNotes}\\n\\n';
    }
    
    if (_note!.rawContent.isNotEmpty) {
      content += 'Raw Content:\\n${_note!.rawContent}';
    }
    
    await Share.share(content, subject: _note!.title);
  }

  @override
  Widget build(BuildContext context) {
    if (_note == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Note'),
        ),
        body: const Center(
          child: Text('Note not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_note!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareNote,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteFormScreen(note: _note),
                  ),
                );
                if (result == true) {
                  _loadNote(); // Refresh note data
                }
              } else if (value == 'reprocess') {
                final success = await context.read<NoteProvider>().reprocessNote(_note!.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note reprocessing started'),
                    ),
                  );
                }
              } else if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Note'),
                    content: Text('Are you sure you want to delete \"${_note!.title}\"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  final success = await context.read<NoteProvider>().deleteNote(_note!.id);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Note deleted successfully'),
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (_note!.rawContent.isNotEmpty)
                const PopupMenuItem(
                  value: 'reprocess',
                  child: ListTile(
                    leading: Icon(Icons.auto_awesome),
                    title: Text('Reprocess with AI'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Key Points'),
            Tab(text: 'Detailed Notes'),
            Tab(text: 'Raw Content'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Processing status banner
          if (_note!.processingStatus != 'completed')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: _getStatusColor(_note!.processingStatus).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(_note!.processingStatus),
                    color: _getStatusColor(_note!.processingStatus),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusMessage(_note!.processingStatus),
                    style: TextStyle(
                      color: _getStatusColor(_note!.processingStatus),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildKeyPoints(),
                _buildDetailedNotes(),
                _buildRawContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPoints() {
    if (_note!.keyPoints.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No key points yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Key points will appear here after AI processing', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _note!.keyPoints.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _note!.keyPoints[index],
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailedNotes() {
    if (_note!.detailedNotes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No detailed notes yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Detailed notes will appear here after AI processing', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _note!.detailedNotes,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
      ),
    );
  }

  Widget _buildRawContent() {
    if (_note!.rawContent.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No raw content', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Record audio or add text content to see it here', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${DateFormat('MMM d, y • HH:mm').format(_note!.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _note!.rawContent,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'processing': return Colors.orange;
      case 'transcribing': return Colors.blue;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle;
      case 'processing': return Icons.auto_awesome;
      case 'transcribing': return Icons.hearing;
      case 'failed': return Icons.error;
      default: return Icons.hourglass_empty;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'processing': return 'AI is processing your note...';
      case 'transcribing': return 'Transcribing audio...';
      case 'failed': return 'Processing failed. Try reprocessing.';
      default: return 'Note is being processed...';
    }
  }
}
