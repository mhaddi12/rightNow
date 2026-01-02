import 'package:chats/services/database_service.dart';
import 'package:chats/services/location_service.dart';
import 'package:chats/services/auth_service.dart';
import 'package:chats/features/home/room_list_screen.dart'; // Will create next
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ActivitySelectionScreen extends StatefulWidget {
  const ActivitySelectionScreen({super.key});

  @override
  State<ActivitySelectionScreen> createState() =>
      _ActivitySelectionScreenState();
}

class _ActivitySelectionScreenState extends State<ActivitySelectionScreen> {
  final List<Map<String, dynamic>> activities = const [
    {'name': 'Working', 'icon': Icons.work_outline, 'color': Color(0xFF6C63FF)},
    {'name': 'Waiting', 'icon': Icons.access_time, 'color': Color(0xFF03DAC6)},
    {'name': 'Studying', 'icon': Icons.menu_book, 'color': Color(0xFFFFB74D)},
    {'name': 'Eating', 'icon': Icons.restaurant, 'color': Color(0xFFF06292)},
    {'name': 'Event', 'icon': Icons.event, 'color': Color(0xFF4FC3F7)},
    {
      'name': 'Chilling',
      'icon': Icons.nightlight_round,
      'color': Color(0xFF9575CD),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Trigger global cleanup of expired rooms on app launch/home screen enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<DatabaseService>(
          context,
          listen: false,
        ).cleanupExpiredRooms();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Right Now'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Provider.of<AuthService>(
                          context,
                          listen: false,
                        ).signOut();
                      },
                      child: const Text(
                        'Log Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "What are you doing\nright now?",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return ActivityCard(
                      name: activity['name'],
                      icon: activity['icon'],
                      color: activity['color'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RoomListScreen(activity: activity['name']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActivityCard({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
