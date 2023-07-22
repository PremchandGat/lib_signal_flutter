part of 'chat_bloc.dart';

@immutable
abstract class ChatEvent {}

class SendMessageEvent extends ChatEvent {}

class ConnectToWebSocketEvent extends ChatEvent {}

class AddMessageEvent extends ChatEvent {
  final Message message;
  AddMessageEvent(this.message);
}

class AddCertificate extends ChatEvent {
  final Uint8List data;
  AddCertificate(this.data);
}

class DecryptMessageAndAddEvent extends ChatEvent {
  final CiphertextMessage message;
  DecryptMessageAndAddEvent(this.message);
}

class SendCertificatesEvent extends ChatEvent {}
