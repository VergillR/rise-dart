import './types.dart';

class Signatures {
  Callback _cb;

  Signatures(Callback cb) : _cb = cb;

  Future getSecondSignatureFee() => _cb(path: '/signatures/fee');
}
