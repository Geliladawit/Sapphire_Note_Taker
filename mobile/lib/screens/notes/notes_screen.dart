import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/note_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/models.dart';
import 'note_detail_screen.dart';
import 'note_form_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  int? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          Consumer<CourseProvider>(
            builder: (context, courseProvider, child) {
              if (courseProvider.courses.isNotEmpty) {
                return PopupMenuButton<int?>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (courseId) {
                    setState(() {
                      _selectedCourseId = courseId;
                    });
                    context.read<NoteProvider>().loadNotes(courseId: courseId);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<int?>(
                      value: null,
                      child: Text('All Notes'),
                    ),
                    ...courseProvider.courses.map(
                      (course) => PopupMenuItem<int?>(
                        value: course.id,
                        child: Text(course.title),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NoteProvider>(
        builder: (context, noteProvider, child) {
          if (noteProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (noteProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    noteProvider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      noteProvider.clearError();
                      noteProvider.loadNotes(courseId: _selectedCourseId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (noteProvider.notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.note_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedCourseId != null ? 'No notes in this course' : 'No notes yet',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first note to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteFormScreen(
                            selectedCourseId: _selectedCourseId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Note'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => noteProvider.loadNotes(courseId: _selectedCourseId),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: noteProvider.notes.length,
              itemBuilder: (context, index) {
                final note = noteProvider.notes[index];
                return _NoteCard(note: note);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteFormScreen(
                selectedCourseId: _selectedCourseId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(noteId: note.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _ProcessingStatusChip(status: note.processingStatus),
                ],
              ),
              if (note.courseTitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note.courseTitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (note.keyPoints.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.keyPoints.first,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, y • HH:mm').format(note.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (note.keyPoints.isNotEmpty)
                    Text(
                      '${note.keyPoints.length} key points',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessingStatusChip extends StatelessWidget {
  final String status;

  const _ProcessingStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'Ready';
        icon = Icons.check_circle;
        break;
      case 'processing':
        color = Colors.orange;
        label = 'Processing';
        icon = Icons.auto_awesome;
        break;
      case 'transcribing':
        color = Colors.blue;
        label = 'Transcribing';
        icon = Icons.hearing;
        break;
      case 'failed':
        color = Colors.red;
        label = 'Failed';
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        label = 'Pending';
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
