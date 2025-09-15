import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../providers/course_provider.dart';
import '../../providers/note_provider.dart';
import '../../models/models.dart';
import '../notes/note_detail_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  late stt.SpeechToText _speechToText;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _isListening = false;
  bool _isAvailable = false;
  String _transcribedText = '';
  Course? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initSpeechToText();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initSpeechToText() async {
    try {
      final status = await Permission.microphone.request();
      if (status == PermissionStatus.granted) {
        _isAvailable = await _speechToText.initialize(
          onStatus: (status) {
            setState(() {
              _isListening = status == 'listening';
            });
            
            if (_isListening) {
              _pulseController.repeat(reverse: true);
            } else {
              _pulseController.stop();
              _pulseController.reset();
            }
          },
          onError: (error) {
            setState(() {
              _isListening = false;
              _pulseController.stop();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speech recognition error: ${error.errorMsg}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      }
    } catch (e) {
      setState(() {
        _isAvailable = false;
      });
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _startListening() async {
    if (!_isAvailable) return;

    setState(() {
      _transcribedText = '';
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _transcribedText = result.recognizedWords;
        });
      },
      // listenFor: const Duration(minutes: 5),
      // pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    _pulseController.stop();
    _pulseController.reset();
  }

  Future<void> _saveNote() async {
    if (_transcribedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No content to save'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Note'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Note Title',
            hintText: 'Enter a title for your note',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, titleController.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (title?.isNotEmpty == true && mounted) {
      final note = await context.read<NoteProvider>().createNote(
        title: title!,
        courseId: _selectedCourse!.id,
        rawContent: _transcribedText,
      );

      if (note != null && mounted) {
        setState(() {
          _transcribedText = '';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved! AI is processing your content...'),
          ),
        );

        // Navigate to note detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(noteId: note.id),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Note'),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      kToolbarHeight,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
          // Course selection
          Consumer<CourseProvider>(
            builder: (context, courseProvider, child) {
              if (courseProvider.courses.isEmpty) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade600),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Create a course first to organize your notes',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.all(16),
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
          
          // Recording area
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Recording button
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? _pulseAnimation.value : 1.0,
                        child: GestureDetector(
                          onTap: _isListening ? _stopListening : _startListening,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: _isListening 
                                  ? Colors.red 
                                  : Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isListening ? Colors.red : Theme.of(context).colorScheme.primary)
                                      .withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    _isListening ? 'Listening...' : 'Tap to start recording',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  
                  if (!_isAvailable) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Microphone not available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Transcribed text area
          if (_transcribedText.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
                minHeight: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Transcribed Text:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _transcribedText = '';
                          });
                        },
                        iconSize: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        _transcribedText,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Action buttons
          if (_transcribedText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _transcribedText = '';
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveNote,
                      child: const Text('Save Note'),
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
