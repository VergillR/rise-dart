import './types.dart';

class Accounts {
  Callback _cb;

  Accounts(Callback cb) : _cb = cb;

  Future getBalance(String address) => _cb(
        queryParameters: {'address': address},
        path: '/accounts/getBalance',
      );

  Future getPublicKey(String address) => _cb(
        queryParameters: {'address': address},
        path: '/accounts/getPublicKey',
      );

  Future getAccount(String address) => _cb(
        queryParameters: {'address': address},
        path: '/accounts',
      );

  Future getAccountByPublicKey(String publicKey) => _cb(
        queryParameters: {'publicKey': publicKey},
        path: '/accounts',
      );

  Future getDelegates(String address) => _cb(
        queryParameters: {'address': address},
        path: '/accounts/delegates',
      );
}
