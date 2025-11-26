import 'package:flutter/material.dart';
import '../models/note.dart';
import 'recording_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Note> _notes = [];

  void _addNote(Note note) {
    setState(() {
      _notes.insert(0, note);
    });
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
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_alt_outlined, size: iconSize, color: Colors.grey[400]),
                      SizedBox(height: isDesktop ? 20 : 16),
                      Text(
                        'Aún no hay notas',
                        style: TextStyle(color: Colors.grey[600], fontSize: emptyTextSize),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(listPadding),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: isDesktop ? 16 : 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                Text(
                                  note.formattedDate,
                                  style: TextStyle(color: Colors.grey[500], fontSize: dateSize),
                                ),
                                Icon(Icons.mic_none, size: micSize, color: Colors.grey[400]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordingScreen(onSave: _addNote),
            ),
          );
        },
        label: const Text('Nueva nota'),
        icon: const Icon(Icons.mic),
      ),
    );
  }
}
