// // lib/widgets/chatgpt_assistant_widget.dart

// import 'package:flutter/material.dart';
// import '../services/chatgpt_assistant_service.dart';

// class ChatGPTAssistantWidget extends StatefulWidget {
//   final int userId;

//   const ChatGPTAssistantWidget({
//     Key? key,
//     required this.userId,
//   }) : super(key: key);

//   @override
//   State<ChatGPTAssistantWidget> createState() => _ChatGPTAssistantWidgetState();
// }

// class _ChatGPTAssistantWidgetState extends State<ChatGPTAssistantWidget> {
//   final ChatGPTAssistantService _assistant = ChatGPTAssistantService.instance;
//   final TextEditingController _queryController = TextEditingController();
//   final List<ChatMessage> _messages = [];
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _addInitialMessage();
//   }

//   void _addInitialMessage() {
//     _messages.add(
//       const ChatMessage(
//         content: '''
//           Cześć! Jestem Twoim asystentem sprzedaży. Mogę Ci pomóc w:
//           - Analizie danych sprzedażowych
//           - Sugerowaniu kolejnych klientów do kontaktu
//           - Planowaniu działań sprzedażowych
//           - Interpretacji trendów
          
//           O co chcesz zapytać?
//         ''',
//         isAssistant: true,
//       ),
//     );
//   }

//   Future<void> _sendMessage(String message) async {
//     if (message.isEmpty) return;

//     setState(() {
//       _messages.add(ChatMessage(content: message, isAssistant: false));
//       _isLoading = true;
//     });

//     try {
//       final response = await _assistant.getAssistantResponse(
//         message,
//         widget.userId,
//       );

//       setState(() {
//         _messages.add(ChatMessage(content: response, isAssistant: true));
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Błąd: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//       _queryController.clear();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(
//           child: ListView.builder(
//             padding: const EdgeInsets.all(8),
//             itemCount: _messages.length,
//             itemBuilder: (context, index) {
//               final message = _messages[index];
//               return _buildMessageBubble(message);
//             },
//           ),
//         ),
//         if (_isLoading)
//           const LinearProgressIndicator(),
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: _queryController,
//                   decoration: const InputDecoration(
//                     hintText: 'Zadaj pytanie...',
//                     border: OutlineInputBorder(),
//                   ),
//                   onSubmitted: _sendMessage,
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.send),
//                 onPressed: () => _sendMessage(_queryController.text),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildMessageBubble(ChatMessage message) {
//     return Align(
//       alignment: message.isAssistant ? Alignment.centerLeft : Alignment.centerRight,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: message.isAssistant ? Colors.blue[100] : Colors.green[100],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.8,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (message.isAssistant)
//               const Padding(
//                 padding: EdgeInsets.only(bottom: 4),
//                 child: Text(
//                   'Asystent',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             Text(message.content),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _queryController.dispose();
//     super.dispose();
//   }
// }

// class ChatMessage {
//   final String content;
//   final bool isAssistant;

//   const ChatMessage({
//     required this.content,
//     required this.isAssistant,
//   });
// }