import 'package:flutter/material.dart';
import 'package:signal_demo/features/chat/bloc/chat_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signal_demo/features/chat/widget/message_widget.dart';

class ChatMessagesView extends StatelessWidget {
  const ChatMessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (previous, current) {
        return current.messages != previous.messages;
      },
      builder: (context, state) {
        return ListView(
          children: [
            for (Message i in state.messages) MessageWidget(message: i)
          ],
        );
      },
    );
  }
}
