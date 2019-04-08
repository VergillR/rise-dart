import 'package:dio/dio.dart';
import 'dart:io';

import './api/accounts.dart';
import './api/blocks.dart';
import './api/delegates.dart';
import './api/loader.dart';
import './api/multisig.dart';
import './api/peers.dart';
import './api/signatures.dart';
import './api/transactions.dart';

class RiseWebApi {
  static const _PATH_SUFFIX = 'api';
  var _dio = Dio();

  Accounts accounts;
  Blocks blocks;
  Delegates delegates;
  Loader loader;
  Multisig multisig;
  Peers peers;
  Signatures signatures;
  Transactions transactions;

  RiseWebApi({String nodeAddress = 'https://twallet.rise.vision/'}) {
    var path = nodeAddress.endsWith('/') ? nodeAddress : nodeAddress + '/';
    _dio.options.baseUrl =
        path.endsWith('/$_PATH_SUFFIX/') ? path : path + '$_PATH_SUFFIX/';
    _dio.options.connectTimeout = 4000;
    _dio.options.contentType = ContentType.json;
    this.accounts = Accounts(callback);
    this.blocks = Blocks(callback);
    this.delegates = Delegates(callback);
    this.loader = Loader(callback);
    this.multisig = Multisig(callback);
    this.peers = Peers(callback);
    this.signatures = Signatures(callback);
    this.transactions = Transactions(callback);
  }

  Future callback(
      {String method = 'get',
      String path = '/',
      Map<String, dynamic> data,
      Map<String, dynamic> queryParameters}) async {
    var response = await _dio.request(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(method: method),
    );
    return response;
  }

  String getNodeAddress() => _dio.options.baseUrl;

  void setNodeAddress(String url) {
    var path = url.endsWith('/') ? url : url + '/';
    _dio.options.baseUrl =
        path.endsWith('/$_PATH_SUFFIX/') ? path : path + '$_PATH_SUFFIX/';
  }
}
