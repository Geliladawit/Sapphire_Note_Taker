import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/models.dart';

class NoteFormScreen extends StatefulWidget {
  final Note? note;
  final int? selectedCourseId;
  
  const NoteFormScreen({
    super.key, 
    this.note,
    this.selectedCourseId,
  });

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Course? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.rawContent ?? '');
    
    // Set selected course from widget or note
    if (widget.note != null) {
      _selectedCourse = context.read<CourseProvider>().getCourseById(widget.note!.courseId);
    } else if (widget.selectedCourseId != null) {
      _selectedCourse = context.read<CourseProvider>().getCourseById(widget.selectedCourseId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCourse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a course'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final noteProvider = context.read<NoteProvider>();
      bool success;

      if (widget.note == null) {
        // Create new note
        final note = await noteProvider.createNote(
          title: _titleController.text.trim(),
          courseId: _selectedCourse!.id,
          rawContent: _contentController.text.trim(),
        );
        success = note != null;
      } else {
        // Update existing note
        success = await noteProvider.updateNote(widget.note!.id, {
          'title': _titleController.text.trim(),
          'raw_content': _contentController.text.trim(),
        });
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.note == null 
                  ? 'Note created successfully'
                  : 'Note updated successfully',
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              noteProvider.error ?? 'Failed to save note',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          Consumer<NoteProvider>(
            builder: (context, noteProvider, child) {
              return TextButton(
                onPressed: noteProvider.isLoading ? null : _saveNote,
                child: noteProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Course selection
            if (widget.note == null)
              Consumer<CourseProvider>(
                builder: (context, courseProvider, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Course>(
                        isExpanded: true,
                        hint: const Text('Select a course'),
                        value: _selectedCourse,
                        onChanged: (course) {
                          setState(() {
                            _selectedCourse = course;
                          });
                        },
                        items: courseProvider.courses.map((course) {
                          return DropdownMenuItem<Course>(
                            value: course,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(course.color.substring(1), radix: 16) + 0xFF000000),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(course.title),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            
            if (widget.note == null) const SizedBox(height: 16),
            
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Note Title',
                hintText: 'e.g., Lecture 1: Introduction',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a note title';
                }
                if (value!.length < 2) {
                  return 'Title must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content (Optional)',
                hintText: 'Enter note content or record audio to auto-transcribe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              minLines: 5,
            ),
            if (_contentController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'AI will automatically generate key points and detailed notes from your content',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
