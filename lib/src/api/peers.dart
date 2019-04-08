import './types.dart';

class Peers {
  Callback _cb;

  Peers(Callback cb) : _cb = cb;

  Future getList(Map<String, dynamic> query) => _cb(
        queryParameters: query,
        path: '/peers',
      );

  Future getByIPPort(Map<String, dynamic> params) => _cb(
        queryParameters: params,
        path: '/peers/get',
      );

  Future version() => _cb(path: '/peers/version');
}
