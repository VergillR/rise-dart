import './types.dart';

class Blocks {
  Callback _cb;

  Blocks(Callback cb) : _cb = cb;

  Future getFeeSchedule() => _cb(path: '/blocks/getFees');

  Future getFee() => _cb(path: '/blocks/getFee');

  Future getReward() => _cb(path: '/blocks/getReward');

  Future getSupply() => _cb(path: '/blocks/getSupply');

  Future getStatus() => _cb(path: '/blocks/getStatus');

  Future getHeight() => _cb(path: '/blocks/getHeight');

  Future getNethash() => _cb(path: '/blocks/getNethash');

  Future getMilestone() => _cb(path: '/blocks/getMilestone');

  Future getBlock(String id) => _cb(
        queryParameters: {'id': id},
        path: '/blocks/get',
      );

  Future getBlocks(Map<String, dynamic> query) => _cb(
        queryParameters: {'query': query},
        path: '/blocks',
      );
}
