import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Note {
  final String id;
  final String text;
  final String audioPath;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.text,
    required this.audioPath,
    required this.createdAt,
  });

  factory Note.create({required String text, required String audioPath}) {
    return Note(
      id: const Uuid().v4(),
      text: text,
      audioPath: audioPath,
      createdAt: DateTime.now(),
    );
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy - h:mm a').format(createdAt);
  }
}
