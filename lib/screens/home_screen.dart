import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'recording_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Note> _notes = [];
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotesFromBackend();
  }

  /// Cargar notas desde Cloudant a través del backend
  Future<void> _loadNotesFromBackend() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar conexión con el servidor
      final isServerAvailable = await _apiService.checkServerHealth();
      if (!isServerAvailable) {
        throw Exception('Backend no disponible. Verifica que esté ejecutándose.');
      }

      final notesData = await _apiService.getNotes();
      final notes = notesData.map((data) => Note.fromJson(data)).toList();

      setState(() {
        _notes.clear();
        _notes.addAll(notes);
        _isLoading = false;
      });

      print('Notas cargadas desde Cloudant: ${notes.length}');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      print('Error cargando notas: $e');
      
      if (mounted) {
        NotificationService.showError(
          context,
          'No se pudieron cargar las notas. Verifica tu conexión.',
        );
      }
    }
  }

  void _addNote(Note note) {
    setState(() {
      _notes.insert(0, note);
    });
  }

  /// Eliminar nota de Cloudant y de la lista local
  Future<void> _deleteNote(Note note, int index) async {
    // Mostrar confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text('¿Estás seguro de que deseas eliminar esta nota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Eliminar del backend si tiene cloudantId
      if (note.cloudantId != null) {
        await _apiService.deleteNote(note.cloudantId!);
      }

      // Eliminar de la lista local
      setState(() {
        _notes.removeAt(index);
      });

      if (mounted) {
        NotificationService.showSuccess(
          context,
          'Nota eliminada correctamente',
        );
      }
    } catch (e) {
      print('Error eliminando nota: $e');
      if (mounted) {
        NotificationService.showError(
          context,
          'No se pudo eliminar la nota. Verifica tu conexión.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 1200;
    
    // Responsive sizes
    final iconSize = isDesktop ? 80.0 : (isTablet ? 72.0 : 64.0);
    final emptyTextSize = isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0);
    final cardPadding = isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0);
    final listPadding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);
    final textSize = isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0);
    final dateSize = isDesktop ? 13.0 : (isTablet ? 12.5 : 12.0);
    final micSize = isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0);
    
    // Max width for desktop
    final maxWidth = isDesktop ? 1000.0 : double.infinity;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas de voz'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Nueva nota de voz',
            iconSize: 28,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecordingScreen(onSave: (note) {
                    _addNote(note);
                    _loadNotesFromBackend();
                  }),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: iconSize, color: Colors.red[300]),
                          SizedBox(height: isDesktop ? 20 : 16),
                          Text(
                            'Error cargando notas',
                            style: TextStyle(color: Colors.red[600], fontSize: emptyTextSize, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadNotesFromBackend,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _notes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mic_none_outlined, size: iconSize * 1.5, color: Theme.of(context).primaryColor.withOpacity(0.3)),
                              SizedBox(height: isDesktop ? 30 : 24),
                              Text(
                                'Aún no hay notas',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: emptyTextSize * 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Graba tu primera nota de voz',
                                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                              ),
                              SizedBox(height: isDesktop ? 40 : 32),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RecordingScreen(onSave: (note) {
                                        _addNote(note);
                                        _loadNotesFromBackend();
                                      }),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.mic, size: isDesktop ? 28 : 24),
                                label: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 24 : 16,
                                    vertical: isDesktop ? 16 : 12,
                                  ),
                                  child: Text(
                                    'Grabar nueva nota',
                                    style: TextStyle(fontSize: isDesktop ? 18 : 16),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
              : ListView.builder(
                  padding: EdgeInsets.all(listPadding),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return Dismissible(
                      key: Key(note.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: EdgeInsets.only(bottom: isDesktop ? 16 : 12),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white, size: 32),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar nota'),
                            content: const Text('¿Estás seguro de que deseas eliminar esta nota?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        try {
                          if (note.cloudantId != null) {
                            await _apiService.deleteNote(note.cloudantId!);
                          }
                          setState(() {
                            _notes.removeAt(index);
                          });
                          if (mounted) {
                            NotificationService.showSuccess(
                              context,
                              'Nota eliminada correctamente',
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            NotificationService.showError(
                              context,
                              'No se pudo eliminar la nota. Intenta de nuevo.',
                            );
                            // Recargar lista si hay error
                            _loadNotesFromBackend();
                          }
                        }
                      },
                      child: Card(
                        margin: EdgeInsets.only(bottom: isDesktop ? 16 : 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // Aquí podrías mostrar un diálogo con el texto completo
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Row(
                                  children: [
                                    const Icon(Icons.mic, size: 24),
                                    const SizedBox(width: 8),
                                    const Expanded(child: Text('Nota de voz')),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(note.text, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(height: 16),
                                      Text(
                                        note.formattedDate,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                      if (note.cloudantId != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'ID: ${note.cloudantId}',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteNote(note, index);
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(cardPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.text,
                                  style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w500),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isDesktop ? 12 : 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note.formattedDate,
                                        style: TextStyle(color: Colors.grey[500], fontSize: dateSize),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (note.cloudantId != null)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Icon(Icons.cloud_done, size: micSize, color: Colors.green[400]),
                                          ),
                                        Icon(Icons.mic_none, size: micSize, color: Colors.grey[400]),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: _notes.isEmpty ? null : FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordingScreen(onSave: (note) {
                _addNote(note);
                // Recargar desde el backend para asegurar sincronización
                _loadNotesFromBackend();
              }),
            ),
          );
        },
        label: const Text('Nueva nota'),
        icon: const Icon(Icons.mic),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
