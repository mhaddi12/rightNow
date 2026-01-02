import 'package:chats/services/database_service.dart';
import 'package:chats/features/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoomListScreen extends StatelessWidget {
  final String activity;

  const RoomListScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(title: Text('$activity Right Now')),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: databaseService.getNearbyRooms(activity),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final rooms = snapshot.data ?? [];

            if (rooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 64,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No active rooms nearby.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Create a new room
                        _createRoom(context, databaseService);
                      },
                      child: const Text('Start a Room'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.group)),
                    title: Text('${activity} Room'),
                    subtitle: Text(
                      'Created just now',
                    ), // Use real time in future
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            roomId: room['id'],
                            activity: activity,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createRoom(context, databaseService),
        label: const Text('Start Room'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createRoom(BuildContext context, DatabaseService db) async {
    // In a real app, we'd get the actual location here.
    // For now we pass dummy location or fetch it properly if we want to be strict.
    // Let's just create it.
    try {
      final roomId = await db.createRoom(
        activity: activity,
        latitude: 0, // Mock
        longitude: 0, // Mock
        creatorId: 'anon', // Should get from AuthService
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room created! It will expire in 1 hour.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(roomId: roomId, activity: activity),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create room: $e')));
      }
    }
  }
}
