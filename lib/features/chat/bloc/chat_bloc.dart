import 'dart:convert';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  var channel =
      WebSocketChannel.connect(Uri.parse('ws://192.168.235.195:8080'));

  @override
  Future<void> close() async {
    await channel.sink.close(status.goingAway);
    return super.close();
  }

  ChatBloc() : super(ChatState()) {
    on<SendMessageEvent>(_sendMessage);
    on<ConnectToWebSocketEvent>(_connectToWebsocket);
    on<AddMessageEvent>(_addMessage);
    on<SendCertificatesEvent>(_sendCertificates);
    on<DecryptMessageAndAddEvent>(_decryptMessage);
  }

  _sendCertificates(SendCertificatesEvent event, Emitter<ChatState> emit) {
    if (state.myCertificates == null) {
      state.installMyCertificates();
    }
    channel.sink.add("Sending certificates");
    channel.sink.add(state.myCertificates!.registrationId.toString());
    channel.sink.add(state.myCertificates!.identityKeyPair!.serialize());
    channel.sink.add(state.myCertificates!.signedPreKey!.serialize());
    for (PreKeyRecord i in state.myCertificates!.preKeys!) {
      channel.sink.add(i.serialize());
    }
    channel.sink.add("done");
  }

  _encryptAndSendMessage(String message) async {
    if (state.remoteUser == null) {
      channel.sink.add("RequestCertificate");
      await Future.delayed(const Duration(seconds: 3));
    }
    if (state.sessionCipher == null) {
      if (state.myCertificates == null) {
        state.installMyCertificates();
      }
    }

    await state.myCertificates!.sessionBuilder!
        .processPreKeyBundle(state.remoteUser!.getKey());

    final sessionCipher = SessionCipher(
        state.myCertificates!.sessionStore!,
        state.myCertificates!.preKeyStore!,
        state.myCertificates!.signedPreKeyStore!,
        state.myCertificates!.identityStore!,
        state.myCertificates!.bobAddress!);
    final ciphertext =
        await sessionCipher.encrypt(Uint8List.fromList(utf8.encode(message)));
    channel.sink.add(ciphertext.serialize());
    print("$ciphertext send");
    add(DecryptMessageAndAddEvent(ciphertext));
  }

  _decryptMessage(
      DecryptMessageAndAddEvent event, Emitter<ChatState> emit) async {
    PreKeySignalMessage ciphertext = event.message as PreKeySignalMessage;
    if (state.remoteUser == null || state.myCertificates == null) return;
    final signalProtocolStore = InMemorySignalProtocolStore(
        state.remoteUser!.remoteIdentityKeyPair!, 2);
    const aliceAddress = SignalProtocolAddress('alice', 2);
    final remoteSessionCipher =
        SessionCipher.fromStore(signalProtocolStore, aliceAddress);

    // for (final p in state.myCertificates!.preKeys!) {
    //   await signalProtocolStore.storePreKey(p.id, p);
    // }
    // await signalProtocolStore.storeSignedPreKey(
    //     state.myCertificates!.signedPreKey!.id,
    //     state.myCertificates!.signedPreKey!);

    // if (ciphertext.getType() == CiphertextMessage.prekeyType) {
    //   await remoteSessionCipher.decryptWithCallback(ciphertext, (plaintext) {
    //     // ignore: avoid_print
    //     print(utf8.decode(plaintext));
    //     add(AddMessageEvent(
    //         Message(message: utf8.decode(plaintext), sender: "you")));
    //   });
    // }

    for (final p in state.remoteUser!.remotePreKeys!) {
      await signalProtocolStore.storePreKey(p.id, p);
    }
    await signalProtocolStore.storeSignedPreKey(
        state.remoteUser!.remoteSignedPreKey!.id,
        state.remoteUser!.remoteSignedPreKey!);

    if (ciphertext.getType() == CiphertextMessage.prekeyType) {
      await remoteSessionCipher.decryptWithCallback(ciphertext, (plaintext) {
        // ignore: avoid_print
        print(utf8.decode(plaintext));
        add(AddMessageEvent(
            Message(message: utf8.decode(plaintext), sender: "you")));
      });
    }
  }

  _sendMessage(SendMessageEvent event, Emitter<ChatState> emit) async {
    await _encryptAndSendMessage(
        state.textEditingControllerForMessageType.text);
    add(AddMessageEvent(Message(
        message: state.textEditingControllerForMessageType.text,
        sender: "Me")));
    state.textEditingControllerForMessageType.clear();
  }

  _addMessage(AddMessageEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(messages: List.of(state.messages)..add(event.message)));
  }

  _connectToWebsocket(ConnectToWebSocketEvent event, Emitter<ChatState> emit) {
    channel.stream.listen((message) {
      String msg = message.runtimeType == String
          ? message
          : String.fromCharCodes(message);
      if (msg == "Sending certificates") {
        state.updateCertificateCount(0);
      } else if (msg == "done") {
        add(AddMessageEvent(Message(message: msg, sender: "User")));
        state.updateCertificateCount(null);
      } else if (state.receivedCertificates != null) {
        addCertificate(message);
      } else {
        if (msg == "RequestCertificate") {
          print("Sending Certificates");
          add(SendCertificatesEvent());
        }
        try {
          PreKeySignalMessage msg = PreKeySignalMessage(message);
          add(DecryptMessageAndAddEvent(msg));
        } catch (e) {}

        add(AddMessageEvent(Message(message: msg, sender: "User")));
      }
    });
  }

  addCertificate(Uint8List data) {
    print("Adding Certificates");
    if (state.receivedCertificates == 0) {
      state.updateCertificates(RemoteCertificates(
          remoteRegId: int.parse(String.fromCharCodes(data))));
    } else if (state.receivedCertificates == 1) {
      state.updateCertificates(RemoteCertificates(
          remoteRegId: state.remoteUser!.remoteRegId,
          remoteIdentityKeyPair: IdentityKeyPair.fromSerialized(data)));
    } else if (state.receivedCertificates == 2) {
      state.updateCertificates(RemoteCertificates(
          remoteRegId: state.remoteUser!.remoteRegId,
          remoteIdentityKeyPair: state.remoteUser!.remoteIdentityKeyPair,
          remoteSignedPreKey: SignedPreKeyRecord.fromSerialized(data)));
    } else if (state.receivedCertificates == 3) {
      state.updateCertificates(RemoteCertificates(
          remoteRegId: state.remoteUser!.remoteRegId,
          remoteIdentityKeyPair: state.remoteUser!.remoteIdentityKeyPair,
          remoteSignedPreKey: state.remoteUser!.remoteSignedPreKey,
          remotePreKeys: [PreKeyRecord.fromBuffer(data)]));
    } else {
      state.updateCertificates(RemoteCertificates(
          remoteRegId: state.remoteUser!.remoteRegId,
          remoteIdentityKeyPair: state.remoteUser!.remoteIdentityKeyPair,
          remoteSignedPreKey: state.remoteUser!.remoteSignedPreKey,
          remotePreKeys: List.of(state.remoteUser!.remotePreKeys!)
            ..add(PreKeyRecord.fromBuffer(data))));
    }
    print(state.remoteUser);
    state.updateCertificateCount(state.receivedCertificates! + 1);
  }
}
