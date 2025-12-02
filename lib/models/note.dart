import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Note {
  final String id;
  final String text;
  final String audioPath;
  final DateTime createdAt;
  final String? cloudantId; // ID del documento en Cloudant (_id)
  final String? cloudantRev; // Revisión del documento en Cloudant (_rev)
  final String? titulo; // Título generado por el backend

  Note({
    required this.id,
    required this.text,
    required this.audioPath,
    required this.createdAt,
    this.cloudantId,
    this.cloudantRev,
    this.titulo,
  });

  // Crear nota local (antes de guardar en backend)
  factory Note.create({required String text, required String audioPath}) {
    return Note(
      id: const Uuid().v4(),
      text: text,
      audioPath: audioPath,
      createdAt: DateTime.now(),
    );
  }

  // Crear nota desde respuesta del backend VozNota
  // Formato del backend: {titulo, texto, id_documento, fecha, _id, _rev}
  factory Note.fromJson(Map<String, dynamic> json) {
    // Parsear fecha - el backend envía en UTC, Flutter lo convierte a hora local
    DateTime parsedDate;
    if (json['fecha'] != null) {
      final dateStr = json['fecha'] as String;
      // Parse como UTC y convertir a hora local automáticamente
      parsedDate = DateTime.parse(dateStr).toLocal();
    } else if (json['created_at'] != null) {
      final dateStr = json['created_at'] as String;
      parsedDate = DateTime.parse(dateStr).toLocal();
    } else if (json['createdAt'] != null) {
      final dateStr = json['createdAt'] as String;
      parsedDate = DateTime.parse(dateStr).toLocal();
    } else {
      parsedDate = DateTime.now();
    }
    
    return Note(
      id: json['id_documento'] ?? json['_id'] ?? json['id'] ?? '',
      text: json['texto'] ?? json['text'] ?? '',
      audioPath: json['audio_path'] ?? json['audioPath'] ?? json['audio_filename'] ?? '',
      createdAt: parsedDate,
      cloudantId: json['_id'] ?? json['id_documento'],
      cloudantRev: json['_rev'],
      titulo: json['titulo'],
    );
  }

  // Convertir a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'texto': text,
      'audio_path': audioPath,
      'fecha': createdAt.toIso8601String(),
      if (titulo != null) 'titulo': titulo,
    };
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy - h:mm a').format(createdAt);
  }
  
  // Obtener el título para mostrar
  String get displayTitle {
    return titulo ?? (text.length > 50 ? '${text.substring(0, 50)}...' : text);
  }
}
