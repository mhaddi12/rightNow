import 'package:chats/services/auth_service.dart';
import 'package:chats/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String activity;

  const ChatScreen({super.key, required this.roomId, required this.activity});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid ?? 'anon';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Room Info'),
                  content: Text(
                    'This is a temporary room for "${widget.activity}".\n\n'
                    'Note: All rooms on "Right Now" expire automatically 1 hour after creation to keep the app fresh.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: dbService.getMessages(widget.roomId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!;
                  return ListView.builder(
                    reverse: true, // Show newest at bottom
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['userId'] == userId;
                      final seenBy = List<String>.from(msg['seenBy'] ?? []);
                      final messageId = msg['id'];
                      final myName = authService.user?.displayName ?? 'Guest';

                      // Mark as seen if not by me and I haven't seen it yet
                      if (!isMe && !seenBy.contains(myName)) {
                        dbService.markMessageAsSeen(
                          roomId: widget.roomId,
                          messageId: messageId,
                          userName: myName,
                        );
                      }

                      return MessageBubble(
                        text: msg['text'] ?? '',
                        isMe: isMe,
                        timestamp: msg['timestamp'],
                        seenBy: seenBy,
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Say something...',
                      ),
                      onSubmitted: (_) =>
                          _sendMessage(dbService, userId, authService),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).primaryColor,
                    onPressed: () =>
                        _sendMessage(dbService, userId, authService),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(DatabaseService db, String userId, AuthService auth) {
    if (_controller.text.trim().isEmpty) return;
    db.sendMessage(
      roomId: widget.roomId,
      text: _controller.text.trim(),
      userId: userId,
      senderName: auth.user?.displayName ?? 'Guest',
    );
    _controller.clear();
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final dynamic timestamp; // Timestamp or null
  final List<String> seenBy;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.timestamp,
    required this.seenBy,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isMe
                  ? Theme.of(context).primaryColor
                  : const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          if (isMe && seenBy.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 8),
              child: Text(
                'Seen by: ${seenBy.join(", ")}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
