import './types.dart';

class Delegates {
  Callback _cb;

  Delegates(Callback cb) : _cb = cb;

  Future getList(Map<String, dynamic> query) => _cb(
        queryParameters: query,
        path: '/delegates',
      );

  Future getByKeyVal(String key, String value) {
    Map<String, dynamic> query = Map();
    query[key] = value;
    return _cb(
      queryParameters: query,
      path: '/delegates/get',
    );
  }

  Future getByUsername(String username) => getByKeyVal('username', username);

  Future getByPublicKey(String publicKey) =>
      getByKeyVal('publicKey', publicKey);

  Future getVoters(String publicKey) =>
      _cb(queryParameters: {'publicKey': publicKey}, path: '/delegates/voters');

  Future getForgedByAccount(dynamic data) {
    return _cb(
      queryParameters: data is String
          ? {
              'generatorPublicKey': data,
            }
          : data,
      path: '/delegates/forging/getForgedByAccount',
    );
  }

  Future getForgingStatus(String publicKey) => _cb(
      queryParameters: {'publicKey': publicKey},
      path: '/delegates/forging/status');

  Future getNextForgers(int limit) =>
      _cb(queryParameters: {'limit': limit}, path: '/delegates/getNextForgers');

  Future search(Map<String, dynamic> query) =>
      _cb(queryParameters: query, path: '/delegates/search');
}
