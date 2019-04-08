import './types.dart';

class Multisig {
  Callback _cb;

  Multisig(Callback cb) : _cb = cb;

  Future getPending(String publicKey) => _cb(
        queryParameters: {'publicKey': publicKey},
        path: '/multisignatures/pending',
      );

  Future getAccounts(String publicKey) => _cb(
        queryParameters: {'publicKey': publicKey},
        path: '/multisignatures/accounts',
      );
}
