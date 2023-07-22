import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signal_demo/features/chat/bloc/chat_bloc.dart';
import 'package:signal_demo/features/chat/widget/message_input.dart';
import 'package:signal_demo/features/chat/widget/messages_view.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User ABC"),
      ),
      body: BlocProvider(
        create: (context) => ChatBloc()..add(ConnectToWebSocketEvent()),
        child: const Column(
          children: [Expanded(child: ChatMessagesView()), ChatMessageInput()],
        ),
      ),
    );
  }
}
