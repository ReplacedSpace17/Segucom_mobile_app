import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:typed_data';
import 'dart:convert'; // Para codificar y decodificar cadenas

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final CacheManager _cacheManager = CacheManager(
    Config(
      'cacheKey',
      stalePeriod: Duration(days: 1),
      maxNrOfCacheObjects: 20,
    ),
  );

  // Método para guardar datos en caché
  Future<void> saveData(String key, String value) async {
    final Uint8List bytes = utf8.encode(value) as Uint8List;
    await _cacheManager.putFile(key, bytes);
  }

  // Método para recuperar datos del caché
  Future<String?> getData(String key) async {
    final file = await _cacheManager.getFileFromCache(key);
    if (file != null) {
      final bytes = await file.file.readAsBytes();
      return utf8.decode(bytes);
    }
    return null;
  }

  // Método para eliminar datos del caché
  Future<void> deleteData(String key) async {
    await _cacheManager.removeFile(key);
  }
}
