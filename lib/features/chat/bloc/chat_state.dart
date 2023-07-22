part of 'chat_bloc.dart';

enum MessageType { text, video, audio, pdf, other }

class SendCertificates {
  int remoteRegId;
  IdentityKeyPair remoteIdentityKeyPair;
  List<PreKeyRecord> remotePreKeys;
  SignedPreKeyRecord remoteSignedPreKey;
  SendCertificates(
      {required this.remoteRegId,
      required this.remoteIdentityKeyPair,
      required this.remotePreKeys,
      required this.remoteSignedPreKey});
}

class RemoteCertificates {
  // Should get remote from the server
  int? remoteRegId;
  IdentityKeyPair? remoteIdentityKeyPair;
  List<PreKeyRecord>? remotePreKeys;
  SignedPreKeyRecord? remoteSignedPreKey;
  PreKeyBundle getKey() {
    if (remoteRegId == null) {
      throw "Remote certificate not found";
    }
    return PreKeyBundle(
        remoteRegId!,
        1,
        remotePreKeys![0].id,
        remotePreKeys![0].getKeyPair().publicKey,
        remoteSignedPreKey!.id,
        remoteSignedPreKey!.getKeyPair().publicKey,
        remoteSignedPreKey!.signature,
        remoteIdentityKeyPair!.getPublicKey());
  }

  RemoteCertificates(
      {this.remoteIdentityKeyPair,
      this.remotePreKeys,
      this.remoteRegId,
      this.remoteSignedPreKey});
}

class MyCertificates {
  IdentityKeyPair? identityKeyPair;
  int? registrationId;
  List<PreKeyRecord>? preKeys;
  InMemorySessionStore? sessionStore;
  InMemoryPreKeyStore? preKeyStore;
  InMemorySignedPreKeyStore? signedPreKeyStore;
  SignedPreKeyRecord? signedPreKey;
  InMemoryIdentityKeyStore? identityStore;
  SignalProtocolAddress? bobAddress;
  SessionBuilder? sessionBuilder;

  install() async {
    identityKeyPair = generateIdentityKeyPair();
    registrationId = generateRegistrationId(false);
    preKeys = generatePreKeys(0, 110);
    signedPreKey = generateSignedPreKey(identityKeyPair!, 0);

    sessionStore = InMemorySessionStore();
    preKeyStore = InMemoryPreKeyStore();
    signedPreKeyStore = InMemorySignedPreKeyStore();
    identityStore = InMemoryIdentityKeyStore(identityKeyPair!, registrationId!);

    for (final p in preKeys!) {
      await preKeyStore!.storePreKey(p.id, p);
    }
    await signedPreKeyStore!.storeSignedPreKey(signedPreKey!.id, signedPreKey!);

    bobAddress = SignalProtocolAddress('bob', 1);
    sessionBuilder = SessionBuilder(sessionStore!, preKeyStore!,
        signedPreKeyStore!, identityStore!, bobAddress!);
  }
}

class Message {
  String message;
  String sender;
  MessageType type;
  Message(
      {required this.message,
      required this.sender,
      this.type = MessageType.text});
}

class ChatState {
  List<Message> messages;
  SessionCipher? sessionCipher;
  RemoteCertificates? remoteUser;
  int? receivedCertificates;
  MyCertificates? myCertificates;

  TextEditingController textEditingControllerForMessageType =
      TextEditingController();

  installMyCertificates() {
    myCertificates = MyCertificates();
    myCertificates!.install();
  }

  updateCertificateCount(int? count) {
    receivedCertificates = count;
  }

  updateCertificates(
    RemoteCertificates? remoteUser,
  ) {
    this.remoteUser = remoteUser;
  }

  updateSessionCipher(SessionCipher cy) {
    sessionCipher = cy;
  }

  copyWith({
    List<Message>? messages,
    SessionCipher? sessionCipher,
  }) {
    return ChatState(
        messages: messages ?? this.messages,
        remoteUser: remoteUser,
        myCertificates: myCertificates,
        receivedCertificates: receivedCertificates,
        sessionCipher: sessionCipher ?? this.sessionCipher);
  }

  ChatState(
      {this.messages = const [],
      this.remoteUser,
      this.sessionCipher,
      this.myCertificates,
      this.receivedCertificates});
}
