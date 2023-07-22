import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

///////////////// Stored in server //////////////////
late int user1RegId;
late IdentityKeyPair user1IdentityKeyPair;
late List<PreKeyRecord> user1PreKeys;
late SignedPreKeyRecord user1SignedPreKey;

late IdentityKeyPair user2identityKeyPair;
late int user2registrationId;
late List<PreKeyRecord> user2preKeys;
late SignedPreKeyRecord user2signedPreKey;

List<CiphertextMessage> encryptedMessages = [];
//////////////////////// END ///////////////////////////

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  late InMemorySessionStore sessionStore;
  late InMemoryPreKeyStore preKeyStore;
  late InMemorySignedPreKeyStore signedPreKeyStore;
  late InMemoryIdentityKeyStore identityStore;
  TextEditingController _controller = TextEditingController();
  late SessionCipher sessionCipher;
  bool isSessionActive = false;
  bool isInstalled = false;

  Future<void> install() async {
    user2identityKeyPair = generateIdentityKeyPair();
    user2registrationId = generateRegistrationId(false);
    user2preKeys = generatePreKeys(0, 110);
    user2signedPreKey = generateSignedPreKey(user2identityKeyPair, 0);
    sessionStore = InMemorySessionStore();
    preKeyStore = InMemoryPreKeyStore();
    signedPreKeyStore = InMemorySignedPreKeyStore();
    identityStore =
        InMemoryIdentityKeyStore(user2identityKeyPair, user2registrationId);

    for (var p in user2preKeys) {
      await preKeyStore.storePreKey(p.id, p);
    }
    await signedPreKeyStore.storeSignedPreKey(
        user2signedPreKey.id, user2signedPreKey);
  }

  PreKeyBundle getFromServer() {
    // Should get remote from the server
    PreKeyBundle retrievedPreKey = PreKeyBundle(
        user1RegId,
        1,
        user1PreKeys[0].id,
        user1PreKeys[0].getKeyPair().publicKey,
        user1SignedPreKey.id,
        user1SignedPreKey.getKeyPair().publicKey,
        user1SignedPreKey.signature,
        user1IdentityKeyPair.getPublicKey());
    return retrievedPreKey;
  }

  sendMessage() async {
    if (_controller.text.isEmpty) return;
    if (!isInstalled) await install();
    if (!isSessionActive) {
      final user1 = SignalProtocolAddress("User1", 1);
      final sessionBuilder = SessionBuilder(
          sessionStore, preKeyStore, signedPreKeyStore, identityStore, user1);
      sessionBuilder.processPreKeyBundle(getFromServer());
      sessionCipher = SessionCipher(
          sessionStore, preKeyStore, signedPreKeyStore, identityStore, user1);
      isSessionActive = true;
    }
    final ciphertext = await sessionCipher
        .encrypt(Uint8List.fromList(utf8.encode(_controller.text)));
    _controller.clear();
    print(ciphertext);
    setState(() {});
    encryptedMessages.add(ciphertext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          for (CiphertextMessage i in encryptedMessages) Text(i.toString())
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            color: Colors.grey,
            width: MediaQuery.of(context).size.width * 0.7,
            child: TextFormField(
              controller: _controller,
            ),
          ),
          IconButton(
              onPressed: () {
                sendMessage();
              },
              icon: const Icon(Icons.send))
        ],
      ),
    );
  }
}

class DemoPage2 extends StatefulWidget {
  const DemoPage2({super.key});

  @override
  State<DemoPage2> createState() => _DemoPage2State();
}

class _DemoPage2State extends State<DemoPage2> {
  late InMemorySessionStore sessionStore;
  late InMemoryPreKeyStore preKeyStore;
  late InMemorySignedPreKeyStore signedPreKeyStore;
  late InMemoryIdentityKeyStore identityStore;
  TextEditingController _controller = TextEditingController();
  late SessionCipher sessionCipher;
  bool isSessionActive = false;
  bool isInstalled = false;

  List<String> receivedMessages = [];

  Future<void> install() async {
    user1IdentityKeyPair = generateIdentityKeyPair();
    user1RegId = generateRegistrationId(false);
    user1PreKeys = generatePreKeys(0, 110);
    user1SignedPreKey = generateSignedPreKey(user1IdentityKeyPair, 0);
    sessionStore = InMemorySessionStore();
    preKeyStore = InMemoryPreKeyStore();
    signedPreKeyStore = InMemorySignedPreKeyStore();
    identityStore =
        InMemoryIdentityKeyStore(user2identityKeyPair, user2registrationId);

    for (var p in user2preKeys) {
      await preKeyStore.storePreKey(p.id, p);
    }
    await signedPreKeyStore.storeSignedPreKey(
        user2signedPreKey.id, user2signedPreKey);
  }

  PreKeyBundle getFromServer() {
    // Should get remote from the server
    PreKeyBundle retrievedPreKey = PreKeyBundle(
        user2registrationId,
        1,
        user2preKeys[0].id,
        user2preKeys[0].getKeyPair().publicKey,
        user2signedPreKey.id,
        user2signedPreKey.getKeyPair().publicKey,
        user2signedPreKey.signature,
        user1IdentityKeyPair.getPublicKey());
    return retrievedPreKey;
  }

  sendMessage() async {
    if (_controller.text.isEmpty) return;
    if (!isInstalled) await install();
    if (!isSessionActive) {
      final remoteAddress = SignalProtocolAddress("User2", 2);
      final sessionBuilder = SessionBuilder(sessionStore, preKeyStore,
          signedPreKeyStore, identityStore, remoteAddress);
      sessionBuilder.processPreKeyBundle(getFromServer());
      sessionCipher = SessionCipher(sessionStore, preKeyStore,
          signedPreKeyStore, identityStore, remoteAddress);
      isSessionActive = true;
    }
    final ciphertext = await sessionCipher
        .encrypt(Uint8List.fromList(utf8.encode(_controller.text)));
    _controller.clear();
    print(ciphertext);
    setState(() {});
    encryptedMessages.add(ciphertext);
  }

  addAndDecryptLastMessage() async {
    final signalProtocolStore =
        InMemorySignalProtocolStore(user2identityKeyPair, 1);
    const aliceAddress = SignalProtocolAddress('User1', 1);
    final remoteSessionCipher =
        SessionCipher.fromStore(signalProtocolStore, aliceAddress);

    for (final p in user2preKeys) {
      await signalProtocolStore.storePreKey(p.id, p);
    }
    await signalProtocolStore.storeSignedPreKey(
        user2signedPreKey.id, user2signedPreKey);

    if (encryptedMessages.last.getType() == CiphertextMessage.prekeyType) {
      await remoteSessionCipher.decryptWithCallback(
          encryptedMessages.last as PreKeySignalMessage, (plaintext) {
        // ignore: avoid_print
        receivedMessages.add(utf8.decode(plaintext));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [for (String i in receivedMessages) Text(i)],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            color: Colors.grey,
            width: MediaQuery.of(context).size.width * 0.7,
            child: TextFormField(
              controller: _controller,
            ),
          ),
          IconButton(
              onPressed: () {
                sendMessage();
              },
              icon: const Icon(Icons.send)),
          IconButton(
              onPressed: () {
                addAndDecryptLastMessage();
              },
              icon: const Icon(Icons.refresh))
        ],
      ),
    );
  }
}
