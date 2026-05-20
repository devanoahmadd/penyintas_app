import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity) : _dio = Dio();

  final Connectivity _connectivity;
  final Dio _dio;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    if (results.every((r) => r == ConnectivityResult.none)) return false;
    try {
      final response = await _dio
          .head('https://dns.google')
          .timeout(const Duration(seconds: 3));
      return (response.statusCode ?? 500) < 500;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    // #4: asyncMap ke isConnected agar stream juga lakukan reachability check,
    // bukan hanya cek adapter (WiFi tanpa internet tetap false)
    return _connectivity.onConnectivityChanged
        .where((results) => results.any((r) => r != ConnectivityResult.none))
        .asyncMap((_) => isConnected);
  }
}
