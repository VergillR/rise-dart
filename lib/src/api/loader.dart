import './types.dart';

class Loader {
  Callback _cb;

  Loader(Callback cb) : _cb = cb;

  Future status() => _cb(path: '/loader/status');

  Future syncStatus() => _cb(path: '/loader/status/sync');
}
