import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
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
  final AuthService _authService = AuthService();

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
            NotificationService.showError(
              context,
              'Se requiere permiso para acceder al micrófono',
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
          // En móvil/desktop, guardamos en el directorio temporal
          final directory = await getTemporaryDirectory();
          path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        }
        
        // Usar la API de la versión 4.4.4
        await _audioRecorder.start(
          path: path,
          encoder: AudioEncoder.wav,
        );
        
        setState(() {
          _isRecording = true;
          _audioPath = path;
          _transcribedText = '';
        });
        
        print('✓ Grabación iniciada: $path');
        
        if (mounted) {
          NotificationService.show(
            context,
            message: 'Grabando... Habla ahora',
            type: NotificationType.success,
            customIcon: Icons.mic,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        throw Exception('No se tiene permiso para grabar audio');
      }
    } catch (e) {
      print('✗ Error al iniciar grabación: $e');
      if (mounted) {
        NotificationService.showError(
          context,
          'No se pudo iniciar la grabación',
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
        NotificationService.showError(
          context,
          'Error al detener la grabación',
        );
      }
    }
  }

  Future<void> _transcribe(String path) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      // Verificar conexión con el backend
      final isServerAvailable = await _apiService.checkServerHealth();
      if (!isServerAvailable) {
        throw Exception('No se puede conectar al servidor');
      }
      
      // Obtener los bytes del archivo de audio
      Uint8List audioBytes;
      
      if (kIsWeb) {
        // En web, el path es una URL blob, descargarla
        final response = await http.get(Uri.parse(path));
        audioBytes = response.bodyBytes;
      } else {
        // En móvil/desktop, leer el archivo
        final file = File(path);
        audioBytes = await file.readAsBytes();
      }
      
      // Transcribir usando el backend (Watson + Cloudant)
      // El backend retorna: {titulo, texto, id_documento, fecha}
      final response = await _apiService.transcribeAudio(path, audioBytes, _authService.token!);
      
      setState(() {
        _transcribedText = response['texto'] ?? 'No se detectó voz';
      });
      
      // Crear la nota inmediatamente después de transcribir
      final note = Note.fromJson({
        'id_documento': response['id_documento'],
        'texto': response['texto'],
        'titulo': response['titulo'],
        'fecha': response['fecha'],
        'audio_path': path,
      });
      
      // Llamar al callback para agregar la nota
      widget.onSave(note);
    } catch (e) {
      print('Error en transcripción: $e');
      
      // Extraer mensaje limpio (viene desde api_service.dart)
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      
      setState(() {
        _transcribedText = 'Error: $errorMsg';
      });
      
      if (mounted) {
        NotificationService.showError(context, errorMsg);
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveNote({bool autoClose = true}) async {
    if (_transcribedText.isNotEmpty && _audioPath != null) {
      // El backend YA guardó la nota en Cloudant cuando transcribió
      // Solo necesitamos notificar y cerrar, NO volver a transcribir
      
      try {
        setState(() {
          _isProcessing = true;
        });
        
        // La nota ya fue guardada durante _transcribeAudio
        // Solo creamos el objeto Note para pasarlo al callback
        // IMPORTANTE: No volver a llamar transcribeAudio aquí
        
        if (mounted) {
          NotificationService.showSuccess(
            context,
            '¡Nota guardada exitosamente!',
          );
          
          // Solo cerrar si autoClose es true
          if (autoClose) {
            // Pequeño delay para que se vea la notificación antes de cerrar
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.pop(context);
            }
          }
        }
      } catch (e) {
        print('Error guardando nota: $e');
        if (mounted) {
          NotificationService.showError(
            context,
            'No se pudo guardar la nota',
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

  Future<bool> _onWillPop() async {
    // Si no hay grabación activa ni audio grabado, permitir salir
    if (!_isRecording && _audioPath == null) {
      return true;
    }
    
    // Si hay una grabación activa o audio sin procesar, mostrar diálogo
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Grabación en progreso'),
          ],
        ),
        content: Text(
          _isRecording 
            ? '¿Qué deseas hacer con la grabación actual?'
            : 'Tienes una grabación sin guardar. ¿Qué deseas hacer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancelar'),
          ),
          if (_isRecording)
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Descartar'),
            ),
          if (!_isRecording && _audioPath != null)
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Descartar'),
            ),
          if (_isRecording)
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, 'save'),
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          if (!_isRecording && _audioPath != null)
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, 'save'),
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
    
    if (result == 'cancel') {
      return false; // No salir
    } else if (result == 'discard') {
      // Detener grabación si está activa
      if (_isRecording) {
        await _audioRecorder.stop();
      }
      // Eliminar archivo si existe
      if (_audioPath != null) {
        try {
          final file = File(_audioPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error eliminando archivo: $e');
        }
      }
      if (mounted) {
        NotificationService.showInfo(context, 'Grabación descartada');
      }
      return true; // Permitir salir
    } else if (result == 'save') {
      // Si está grabando, detener primero
      if (_isRecording) {
        await _stopRecording();
      }
      // Procesar y guardar
      if (_audioPath != null) {
        await _transcribe(_audioPath!);
        await _saveNote(autoClose: false);
      }
      return true; // Permitir salir después de guardar
    }
    
    return false; // Por defecto, no salir
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
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
      ),
    );
  }
}
