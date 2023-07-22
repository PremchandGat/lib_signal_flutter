import 'package:flutter/material.dart';
import 'package:signal_demo/features/chat/bloc/chat_bloc.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({super.key, required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: message.sender == "me"
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: message.sender == "me" ? Colors.green : Colors.blueGrey,
              borderRadius: BorderRadius.circular(8)),
          child: Text(message.message),
        )
      ],
    );
  }
}
