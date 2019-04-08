import 'dart:convert';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:fixnum/fixnum.dart';
import 'package:hex/hex.dart';
import 'package:raw/raw.dart';
import './utils/BigInt.dart';

/// Includes RISE offline crypto functions (based on https://github.com/vekexasia/dpos-offline/):
/// deriving a keypair, signing and verifying messages and transactions, transforming transactions, calculating addresses and transaction id's
/// Main function is createSignedAndPostableTransaction() which produces a completely signed and finalized transaction object.
class RiseOfflineSigning {
  static const int _RISE_EPOCH = 1464109200;
  static final Uint8List _prefix =
      Uint8List.fromList(utf8.encode('RISE Signed Message:\n'));

  static const Map<String, dynamic> BASE_TRANSACTION_OBJECT = const {
    'recipientId': null,
    'senderId': null,
    'amount': 0,
    'senderPublicKey': null,
    'requesterPublicKey': null, // optional
    'timestamp': null, // called nonce
    'fee': null,
    'asset': null,
    // 0 = send, 1 = register 2nd sig, 2 = register a delegate, 3 = vote for a delegate, 4 = register a multisig
    // NOT YET IMPLEMENTED: 5 = register dapp application, 6 = transfer from RISE into sidechain, 7 = transfer RISE from sidechain to mainchain
    'type': null,
    'id': null,
    'signature': null,
    'signSignature': null, // optional
    'signatures': null // optional
  };

  static const Map<String, dynamic> BASE_TRANSACTION_OBJECT_RISE_V2 = const {
    'recipientId': null,
    'senderId': null,
    'amount': '0',
    'senderPubData': null,
    'timestamp': null, // called nonce
    'fee': null,
    'asset': null,
    'type': null,
    'id': null,
    'signatures': [],
    'version': 0,
  };

  static const Map<String, int> _FEES = const {
    'multisignature': 500000000,
    'register-delegate': 2500000000,
    'second-signature': 500000000,
    'send': 10000000,
    'vote': 100000000,
    'sendMultiplier': 1000000, // RISE V2
  };

  RiseOfflineSigning();

  Map<String, dynamic> getBaseTransactionObject({int version = 1}) {
    return version == 1
        ? BASE_TRANSACTION_OBJECT
        : BASE_TRANSACTION_OBJECT_RISE_V2;
  }

  Uint8List signablePayload(dynamic message) {
    Uint8List msgBuf;
    if (message is String) {
      msgBuf = Uint8List.fromList(utf8.encode(message));
    } else if (message is Uint8List) {
      msgBuf = Uint8List.fromList(message);
    } else {
      throw ArgumentError(
          'signablePayload received message that was not of type String or Uint8List; given type was ${message.runtimeType}');
    }
    RawWriter w = RawWriter.withCapacity(8, isExpanding: true);
    w.writeVarUint(_prefix.length);
    w.writeBytes(_prefix);
    w.writeVarUint(msgBuf.length);
    w.writeBytes(msgBuf);
    Uint8List buf = w.toUint8ListCopy();
    Digest sha256 = new Digest('SHA-256');
    return sha256.process(sha256.process(buf));
  }

  Future<Uint8List> signMessage(
          String message, Map<String, Uint8List> keypair) async =>
      await Sodium.cryptoSignDetached(
          this.signablePayload(message), keypair['sk']);

  Future<Uint8List> signMessageBytes(
          Uint8List messageBytes, Map<String, Uint8List> keypair) async =>
      await Sodium.cryptoSignDetached(
          this.signablePayload(messageBytes), keypair['sk']);

  Future<Uint8List> signTransaction(
          Uint8List transaction, Map<String, Uint8List> keypair) async =>
      await Sodium.cryptoSignDetached(transaction, keypair['sk']);

  Future<bool> verifyMessage(
      Uint8List signature, String message, dynamic givenPublicKey) async {
    if (!(givenPublicKey is String) && !(givenPublicKey is Uint8List)) {
      throw ArgumentError('givenPublicKey was not a String or Uint8List');
    }
    return await Sodium.cryptoSignVerifyDetached(
        signature,
        this.signablePayload(message),
        givenPublicKey is String ? HEX.decode(givenPublicKey) : givenPublicKey);
  }

  Future<bool> verifyMessageBytes(Uint8List signature, Uint8List messageBytes,
      dynamic givenPublicKey) async {
    if (!(givenPublicKey is String) && !(givenPublicKey is Uint8List)) {
      throw ArgumentError('givenPublicKey was not a String or Uint8List');
    }
    return await Sodium.cryptoSignVerifyDetached(
        signature,
        this.signablePayload(messageBytes),
        givenPublicKey is String ? HEX.decode(givenPublicKey) : givenPublicKey);
  }

  Future<Map<String, Uint8List>> deriveKeypair(Uint8List seed) {
    return Sodium.cryptoSignSeedKeypair(seed)
        .then((res) => {'sk': res['sk'], 'pk': res['pk']})
        .catchError((err) {
      throw err;
    });
  }

  String calcAddress(dynamic publicKey) {
    if (!(publicKey is String) && !(publicKey is Uint8List)) {
      throw ArgumentError('publicKey was not a String or Uint8List');
    }
    Digest sh = new Digest('SHA-256');
    var input =
        sh.process(publicKey is String ? HEX.decode(publicKey) : publicKey);
    List<int> buffer = <int>[];
    for (int i = 0; i < 8; i++) buffer.add(input[7 - i]);
    return '${decodeBigInt(buffer)}R';
  }

  int createNonce() {
    DateTime other =
        DateTime.fromMillisecondsSinceEpoch(_RISE_EPOCH * 1000, isUtc: true);
    return (DateTime.now().toUtc().difference(other)).inSeconds;
  }

  Uint8List getChildBytes(Map<String, dynamic> tx) {
    if (tx['type'] == 0) {
      if (tx['asset'] != null && tx['asset']['data'] != null) {
        return Uint8List.fromList(utf8.encode(tx['asset']['data']));
      }
    } else if (tx['type'] == 1) {
      return Uint8List.fromList(
          HEX.decode(tx['asset']['signature']['publicKey']));
    } else if (tx['type'] == 2) {
      return Uint8List.fromList(
          utf8.encode(tx['asset']['delegate']['username']));
    } else if (tx['type'] == 3) {
      return Uint8List.fromList(utf8.encode(tx['asset']['votes'].join('')));
    } else if (tx['type'] == 4) {
      Uint8List keysList = Uint8List.fromList(
          utf8.encode(tx['asset']['multisignature']['keysgroup'].join('')));

      var w = new RawWriter.withCapacity(1 + 1 + keysList.length,
          isExpanding: true);
      w.writeUint8(tx['asset']['multisignature']['min']);
      w.writeUint8(tx['asset']['multisignature']['lifetime']);

      for (var i = 0; i < keysList.length; i++) w.writeUint8(keysList[i]);

      return w.toUint8ListCopy();
    }
    return Uint8List(0);
  }

  Uint8List toBytes(Map<String, dynamic> tx,
      {bool skipSign = false, bool skipSecondSign = false}) {
    Uint8List assetBytes = this.getChildBytes(tx);

    RawWriter writer = RawWriter.withCapacity(
        1 + 4 + 32 + 32 + 8 + 8 + 64 + 64 + assetBytes.length,
        isExpanding: true);
    writer.writeUint8(tx['type']);
    writer.writeUint32(tx['timestamp'], Endian.little);
    tx['senderPublicKey'] is Uint8List
        ? writer.writeBytes(tx['senderPublicKey'])
        : writer.writeBytes(utf8.encode(tx['senderPublicKey']));

    if (tx['requesterPublicKey'] != null) {
      tx['requesterPublicKey'] is Uint8List
          ? writer.writeBytes(tx['requesterPublicKey'])
          : writer.writeBytes(utf8.encode(tx['requesterPublicKey']));
    }
    if (tx['recipientId'] != null) {
      String s = tx['recipientId'].substring(0, tx['recipientId'].length - 1);
      writer.writeFixInt64(Int64.parseInt(s), Endian.little);
    } else {
      writer.writeZeroes(8);
    }
    writer.writeFixInt64(Int64(tx['amount']), Endian.big);

    writer.writeBytes(assetBytes);
    if (!skipSign && tx['signature'] != null) {
      tx['signature'] is Uint8List
          ? writer.writeBytes(tx['signature'])
          : writer.writeBytes(utf8.encode(tx['signature']));
    }
    if (!skipSecondSign && tx['signSignature'] != null) {
      tx['signSignature'] is Uint8List
          ? writer.writeBytes(tx['signSignature'])
          : writer.writeBytes(utf8.encode(tx['signSignature']));
    }
    return writer.toUint8ListCopy();
  }

  Future<String> getTransactionId(Map<String, dynamic> transaction) async {
    Digest sha256 = new Digest('SHA-256');
    var input = sha256
        .process(toBytes(transaction, skipSign: false, skipSecondSign: false));
    List<int> buffer = <int>[];
    for (int i = 0; i < 8; i++) buffer.add(input[7 - i]);
    return '${decodeBigInt(buffer)}';
  }

  Map<String, dynamic> toPostable(Map<String, dynamic> tx) {
    if (tx['requesterPublicKey'] != null &&
        !(tx['requesterPublicKey'] is String)) {
      tx['requesterPublicKey'] = HEX.encode(tx['requesterPublicKey']);
    }
    if (tx['senderPublicKey'] != null && !(tx['senderPublicKey'] is String)) {
      tx['senderPublicKey'] = HEX.encode(tx['senderPublicKey']);
    }
    if (tx['signature'] != null && !(tx['signature'] is String)) {
      tx['signature'] = HEX.encode(tx['signature']);
    }
    if (tx['signSignature'] != null && !(tx['signSignature'] is String)) {
      tx['signSignature'] = HEX.encode(tx['signSignature']);
    }
    if (tx['signatures'] != null && tx['signatures'] is List) {
      tx['signatures'] =
          tx['signatures'].map((s) => s is String ? s : HEX.encode(s));
    }
    if (tx['senderId'] == null && tx['senderPublicKey'] != null) {
      Uint8List k = tx['senderPublicKey'] is String
          ? HEX.decode(tx['senderPublicKey'])
          : tx['senderPublicKey'];
      tx['senderId'] = this.calcAddress(k);
    }

    ['requesterPublicKey', 'senderPublicKey', 'signSignature', 'signatures']
        .forEach((e) {
      if (tx[e] == null) tx.remove(e);
    });

    return tx;
  }

  Map<String, dynamic> fromPostable(Map<String, dynamic> postableTx) {
    Map<String, dynamic> t = Map();
    t.addAll(postableTx);
    if (postableTx['amount'] is String) {
      t['amount'] = int.parse(postableTx['amount'], radix: 10);
    }
    if (postableTx['fee'] is String) {
      t['fee'] = int.parse(postableTx['fee'], radix: 10);
    }
    if (postableTx['requesterPublicKey'] != null) {
      t['requesterPublicKey'] =
          Uint8List.fromList(HEX.decode(postableTx['requesterPublicKey']));
    }
    if (postableTx['senderPublicKey'] != null) {
      t['senderPublicKey'] =
          Uint8List.fromList(HEX.decode(postableTx['senderPublicKey']));
    }
    if (postableTx['signSignature'] != null) {
      t['signSignature'] =
          Uint8List.fromList(HEX.decode(postableTx['signSignature']));
    }
    if (postableTx['signature'] != null) {
      t['signature'] = Uint8List.fromList(HEX.decode(postableTx['signature']));
    }
    if (postableTx['signatures'] != null) {
      t['signatures'] =
          Uint8List.fromList(HEX.decode(postableTx['signatures']));
    }
    [
      'requesterPublicKey',
      'senderPublicKey',
      'signSignature',
      'signatures',
      'signature'
    ].forEach((e) {
      if (t[e] == null) t.remove(e);
    });
    return t;
  }

  Future<Uint8List> calcSignature(
      Map<String, dynamic> tx, Map<String, Uint8List> keypair) async {
    Digest sha256 = new Digest('SHA-256');
    Uint8List signedBytes =
        await signTransaction(sha256.process(toBytes(tx)), keypair);
    return signedBytes;
  }

  Future<Map<String, dynamic>> createSignedAndPostableTransaction(
      {@required Map<String, dynamic> transaction,
      @required Map<String, Uint8List> firstKeypair,
      Map<String, Uint8List> secondKeypair}) async {
    Map<String, dynamic> tx = this.transform(transaction, firstKeypair['pk']);
    Digest sha256 = new Digest('SHA-256');
    Uint8List signedBytes =
        await signTransaction(sha256.process(toBytes(tx)), firstKeypair);

    tx['signature'] = signedBytes;
    String tid;
    if (secondKeypair == null) {
      tid = await getTransactionId(tx);
      tx['id'] = tid;
    }
    tx = toPostable(tx);

    if (secondKeypair != null) {
      signedBytes =
          await signTransaction(sha256.process(toBytes(tx)), secondKeypair);
      tx['signSignature'] = signedBytes;
      tid = await getTransactionId(tx);
      tx['id'] = tid;
      tx = toPostable(tx);
    }
    return tx;
  }

  Map<String, dynamic> transform(Map<String, dynamic> tx, Uint8List publicKey) {
    Map<String, dynamic> t = Map();
    t.addAll(this.getBaseTransactionObject());
    final String address = this.calcAddress(publicKey);

    t['type'] = [
      'send',
      'second-signature',
      'register-delegate',
      'vote',
      'multisignature'
    ].indexOf(tx['kind']);

    if (tx['type'] == -1) {
      print("ERROR: tx[kind] has incorrect value: ${tx['kind']}");
      throw new Error();
    }

    if (tx['fee'] == null) {
      t['fee'] = _FEES[tx['kind']];
    } else {
      t['fee'] = tx['fee'];
    }

    t['senderPublicKey'] = publicKey;
    t['senderId'] = address;

    if (tx['kind'] == 'send') {
      t['amount'] = tx['amount'];
      t['recipientId'] = tx['recipient'];
      if (tx['memo'] != null) {
        t['asset'] = {'data': tx['memo']};
      }
    }

    if (tx['nonce'] != null) {
      t['timestamp'] = tx['nonce'];
    } else {
      t['timestamp'] = this.createNonce();
    }

    if (tx['kind'] == 'vote') {
      t['recipientId'] = address;
      List<String> votes = [];
      for (Map<String, dynamic> pref in tx['preferences']) {
        votes.add("${pref['action']}${pref['delegateIdentifier']}");
      }
      t['asset'] = {'votes': votes};
    } else if (tx['kind'] == 'register-delegate') {
      t['asset'] = {
        'delegate': {'username': tx['identifier']}
      };
    } else if (tx['kind'] == 'second-signature') {
      t['asset'] = {
        'signature': {'publicKey': tx['publicKey']}
      };
    } else if (tx['kind'] == 'multisignature') {
      t['asset'] = {
        'multisignature': {
          'keysgroup': tx['config']['added']
              .map((p) => '+$p')
              .followedBy(tx['config']['removed'].map((p) => '-$p')),
          'lifetime': tx['lifetime'],
          'min': tx['min'],
        },
      };
    }

    if (tx['signature'] != null) {
      t['signature'] = tx['signature'];
    }

    if (tx['extraSignatures'] != null) {
      if (tx['extraSignatures'].length == 1) {
        t['signSignature'] = tx['extraSignatures'][0];
      } else {
        t['signatures'] = tx['extraSignatures'];
      }
    }

    return t;
  }
}
