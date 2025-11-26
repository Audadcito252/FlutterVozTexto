import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
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
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _audioRecorder = Record();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      // En web, el permiso se solicita automáticamente al iniciar la grabación
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Se requiere permiso para el micrófono')),
            );
          }
          return;
        }
      }
      print('✓ Grabadora inicializada correctamente');
    } catch (e) {
      print('Error iniciando grabadora: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      print('🎤 Iniciando grabación...');
      
      if (await _audioRecorder.hasPermission()) {
        String path;
        
        if (kIsWeb) {
          // En web, no necesitamos directorio, el audio se guarda en memoria
          path = 'audio_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          // En móvil, guardamos en el directorio temporal
          final directory = await getTemporaryDirectory();
          path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        }
        
        // Configuración mejorada para grabación
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 44100,
            bitRate: 128000,
          ),
          path: path,
        );
        
        setState(() {
          _isRecording = true;
          _audioPath = path;
          _transcribedText = '';
        });
        
        print('✓ Grabación iniciada: $path');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎙️ Grabando... Habla ahora'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('No se tiene permiso para grabar audio');
      }
    } catch (e) {
      print('✗ Error al iniciar grabación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      print('🛑 Deteniendo grabación...');
      
      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
      });
      
      print('✓ Grabación detenida. Path: $path');
      
      if (path != null && path.isNotEmpty) {
        setState(() {
          _audioPath = path;
        });
        await _transcribe(path);
      } else {
        throw Exception('No se pudo obtener el archivo de audio');
      }
    } catch (e) {
      print('✗ Error al detener grabación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _transcribe(String path) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      final File audioFile = File(path);
      
      // Verificar conexión con el backend
      final isServerAvailable = await _apiService.checkServerHealth();
      if (!isServerAvailable) {
        throw Exception('No se puede conectar al servidor. Verifica que el backend esté ejecutándose en el puerto 8080.');
      }
      
      // Transcribir usando el backend (Watson + Cloudant)
      // El backend retorna: {titulo, texto, id_documento, fecha}
      final response = await _apiService.transcribeAudio(audioFile);
      
      setState(() {
        _transcribedText = response['texto'] ?? 'No se detectó voz';
      });
    } catch (e) {
      setState(() {
        _transcribedText = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveNote() async {
    if (_transcribedText.isNotEmpty && _audioPath != null) {
      // El backend YA guardó la nota en Cloudant cuando transcribió
      // Solo necesitamos obtener los datos del último transcribe
      
      try {
        setState(() {
          _isProcessing = true;
        });
        
        final File audioFile = File(_audioPath!);
        
        // Volver a obtener la respuesta completa (incluye id_documento)
        final response = await _apiService.transcribeAudio(audioFile);
        
        print('Respuesta del backend: $response');
        
        // Crear objeto Note con los datos de Cloudant
        final note = Note.fromJson({
          'id_documento': response['id_documento'],
          'texto': response['texto'],
          'titulo': response['titulo'],
          'fecha': response['fecha'],
          'audio_path': _audioPath,
        });
        
        widget.onSave(note);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Nota guardada exitosamente en Cloudant!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error guardando nota: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
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
