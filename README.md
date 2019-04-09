# rise-dart
The complete RISE Dart cryptography library which includes the Dart versions of the modules 'dpos-offline' and 'rise-api'. Also, the module [bip39](https://pub.dartlang.org/packages/bip39) is included in this package.
This library was made for use with [Flutter](https://flutter.dev).

## Offline library (Dart implementation of dpos-offline)
Includes all functions from [dpos-offline](https://github.com/vekexasia/dpos-offline). After calling `import 'package:rise/rise.dart';`, the Rise object is available. `Rise.offline` accesses the dpos-offline signing module.
```dart


// create account
var mnemonic1 = Rise.offline.generateMnemonic();
var mnemonic2 = Rise.offline.generateMnemonic();
var keypair1 = await Rise.offline.deriveKeypair(mnemonic1);
var keypair2 = await Rise.offline.deriveKeypair(mnemonic2);
print(keypair1['sk']); // output first private key
print(keypair1['pk']); // output first public key
var address = Rise.offline.calcAddress(keypair1['pk']);
print(address); // output address

// create transaction
var transaction = {
  'kind': 'send',
  'amount': 100000000,
  'recipient': '12345678901234567R'
};
// one convenience method produces a fully signed transaction object ready to be posted to the RISE network
// note: all individual functions (e.g. calcSignature, toPostable, toBytes, getTransactionId (identifier), etc.) are still available for use
var sendTx = await Rise.offline.createSignedAndPostableTransaction(transaction: transaction, firstKeypair: keypair1, secondKeypair: keypair2);
print(sendTx);
```

## Api library (Dart implementation of rise-api)
Includes all functions from [rise-api](https://github.com/RiseVision/rise-ts). After calling `import 'package:rise/rise.dart';`, the Rise object is available. `Rise.api` accesses the rise-api module.
Deprecated functions are not available.
```dart
// set the node address if you want to use the mainnet (default nodeAddress is https://twallet.rise.vision which uses the testnet)
// Rise.api.setNodeAddress('https://wallet.rise.vision');
print(Rise.api.getNodeAddress());

Map<String, dynamic> query = {'type': 2, 'fromHeight': 1871470};
var res1 = await Rise.api.transactions.getList(query);
print(res1);
var res2 = await Rise.api.accounts.getPublicKey('3917106276365326430R');
print(res2);
var res3 = await Rise.api.blocks.getBlock('10576897963853633953');
print(res3);

// post a fully signed transaction
var sendTx = await Rise.offline.createSignedAndPostableTransaction(transaction: transaction, firstKeypair: keypair1, secondKeypair: keypair2);
Rise.api.transactions.put(sendTx).then((res) => print(res)).catchError((err) => print(err));
```

## License
This library is available under the MIT License. 2019 Vergill Lemmert.
