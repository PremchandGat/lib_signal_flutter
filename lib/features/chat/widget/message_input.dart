import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signal_demo/features/chat/bloc/chat_bloc.dart';

class ChatMessageInput extends StatelessWidget {
  const ChatMessageInput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(builder: (context, state) {
      return Container(
        decoration: BoxDecoration(
            color: Colors.grey, borderRadius: BorderRadius.circular(10)),
        child: TextField(
          controller: state.textEditingControllerForMessageType,
          decoration: InputDecoration(
              suffixIcon: IconButton.filled(
                  onPressed: () =>
                      context.read<ChatBloc>().add(SendMessageEvent()),
                  icon: const Icon(Icons.send))),
        ),
      );
    });
  }
}
