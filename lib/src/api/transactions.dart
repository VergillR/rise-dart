import './types.dart';

class Transactions {
  Callback _cb;

  Transactions(Callback cb) : _cb = cb;

  Future get(String id) =>
      _cb(queryParameters: {'id': id}, path: '/transactions/get');

  Future count() => _cb(path: '/transactions/count');

  Future getList(Map<String, dynamic> query) => _cb(
        queryParameters: query,
        path: '/transactions',
      );

  Future getUnconfirmedTransactions() => _cb(path: '/transactions/unconfirmed');

  Future getUnconfirmedTransaction(String id) => _cb(
        queryParameters: {id: id},
        path: '/transactions/unconfirmed/get',
      );

  Future put(dynamic tx) {
    if (tx is List) {
      return _cb(
        data: {'transactions': tx},
        method: 'put',
        path: '/transactions',
      );
    }
    return _cb(
      data: {'transaction': tx},
      method: 'put',
      path: '/transactions',
    );
  }
}
