import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/watson_service.dart';
import '../models/note.dart';

class RecordingScreen extends StatefulWidget {
  final Function(Note) onSave;

  const RecordingScreen({super.key, required this.onSave});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late Record _audioRecorder;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _audioPath;
  String _transcribedText = '';
  final WatsonService _watsonService = WatsonService();

  @override
  void initState() {
    super.initState();
    _audioRecorder = Record();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se requiere permiso para el micrófono')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        
        // In v4, start takes path as a named argument or positional depending on exact version, 
        // but usually: start(path: path, encoder: AudioEncoder.wav)
        // Let's try the standard v4 signature.
        await _audioRecorder.start(path: path, encoder: AudioEncoder.wav);
        
        setState(() {
          _isRecording = true;
          _audioPath = path;
          _transcribedText = '';
        });
      }
    } catch (e) {
      print('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
      if (path != null) {
        _transcribe(path);
      }
    } catch (e) {
      print('Error stopping record: $e');
    }
  }

  Future<void> _transcribe(String path) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      final File audioFile = File(path);
      final text = await _watsonService.transcribeAudio(audioFile);
      setState(() {
        _transcribedText = text;
      });
    } catch (e) {
      setState(() {
        _transcribedText = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _saveNote() {
    if (_transcribedText.isNotEmpty && _audioPath != null) {
      final note = Note.create(text: _transcribedText, audioPath: _audioPath!);
      widget.onSave(note);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 1200;
    
    // Responsive sizes
    final padding = isDesktop ? 32.0 : (isTablet ? 28.0 : 24.0);
    final textSize = isDesktop ? 20.0 : (isTablet ? 19.0 : 18.0);
    final buttonSize = isDesktop ? 90.0 : (isTablet ? 85.0 : 80.0);
    final iconSize = isDesktop ? 54.0 : (isTablet ? 51.0 : 48.0);
    final fabIconSize = isDesktop ? 40.0 : (isTablet ? 38.0 : 36.0);
    final spacing = isDesktop ? 40.0 : (isTablet ? 36.0 : 32.0);
    final statusTextSize = isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0);
    
    // Max width for desktop
    final maxWidth = isDesktop ? 800.0 : double.infinity;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva nota de voz')),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(isDesktop ? 20 : 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _transcribedText.isEmpty
                              ? (_isRecording ? 'Listening...' : 'Toque grabar y comienze a hablar...')
                              : _transcribedText,
                          style: TextStyle(fontSize: textSize, height: 1.5),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing),
                  if (_isRecording)
                    Center(
                      child: GestureDetector(
                        onTap: _stopRecording,
                        child: Container(
                          height: buttonSize,
                          width: buttonSize,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(Icons.stop_rounded, color: Colors.red, size: iconSize),
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton.large(
                          onPressed: _startRecording,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(Icons.mic, size: fabIconSize),
                        ),
                        if (_transcribedText.isNotEmpty)
                          FloatingActionButton.large(
                            onPressed: _saveNote,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.check, size: fabIconSize),
                          ),
                      ],
                    ),
                  SizedBox(height: isDesktop ? 24 : 20),
                  Text(
                    _isRecording ? 'Grabando...' : 'Listo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: statusTextSize,
                      color: _isRecording ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
