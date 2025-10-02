import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  late SharedPreferences _prefs;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, dynamic> _syncQueue = {};

  // 캐시 TTL (Time To Live) - 5분
  static const int cacheTTL = 5 * 60 * 1000;
  static const int diskCacheTTL = 24 * 60 * 60 * 1000; // 24시간
  static const int offlineCacheTTL = 7 * 24 * 60 * 60 * 1000; // 7일

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSyncQueue();
    await _cleanupExpiredCache();
  }

  // 동기화 큐 로드
  Future<void> _loadSyncQueue() async {
    final queueJson = _prefs.getString('sync_queue');
    if (queueJson != null) {
      final queue = jsonDecode(queueJson) as Map<String, dynamic>;
      _syncQueue.addAll(queue);
    }
  }

  // 만료된 캐시 정리
  Future<void> _cleanupExpiredCache() async {
    final keys = _prefs.getKeys().toList();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final key in keys) {
      if (key.startsWith('cache_') || key.startsWith('offline_')) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          try {
            final data = jsonDecode(jsonString) as Map<String, dynamic>;
            final timestamp = data['timestamp'] as int;
            final ttl = key.startsWith('offline_') ? offlineCacheTTL : diskCacheTTL;

            if (now - timestamp > ttl) {
              await _prefs.remove(key);
            }
          } catch (e) {
            // 잘못된 형식의 데이터 제거
            await _prefs.remove(key);
          }
        }
      }
    }
  }

  // 데이터 무결성 검증을 위한 해시 생성
  String _generateHash(dynamic data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 데이터 무결성 검증
  bool _verifyDataIntegrity(dynamic data, String? expectedHash) {
    if (expectedHash == null) return true;
    return _generateHash(data) == expectedHash;
  }

  // 메모리 캐시에 데이터 저장
  void setMemoryCache(String key, dynamic value) {
    _memoryCache[key] = {
      'data': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // 메모리 캐시에서 데이터 가져오기
  dynamic getMemoryCache(String key) {
    final cached = _memoryCache[key];
    if (cached == null) return null;

    final timestamp = cached['timestamp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;

    // TTL 체크
    if (now - timestamp > cacheTTL) {
      _memoryCache.remove(key);
      return null;
    }

    return cached['data'];
  }

  // 메모리 캐시에서 데이터 제거
  void removeMemoryCache(String key) {
    _memoryCache.remove(key);
  }

  // SharedPreferences에 JSON 데이터 저장
  Future<void> setCache(String key, Map<String, dynamic> value) async {
    final data = {
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs.setString(key, jsonEncode(data));
  }

  // SharedPreferences에서 JSON 데이터 가져오기
  Future<Map<String, dynamic>?> getCache(String key) async {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;

    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final timestamp = data['timestamp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;

    // TTL 체크 (24시간)
    if (now - timestamp > 24 * 60 * 60 * 1000) {
      await _prefs.remove(key);
      return null;
    }

    return data['value'] as Map<String, dynamic>;
  }

  // 리스트 데이터 캐싱
  Future<void> setCacheList(String key, List<dynamic> value) async {
    final data = {
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs.setString(key, jsonEncode(data));
  }

  // 리스트 데이터 가져오기
  Future<List<dynamic>?> getCacheList(String key) async {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;

    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final timestamp = data['timestamp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;

    // TTL 체크 (24시간)
    if (now - timestamp > 24 * 60 * 60 * 1000) {
      await _prefs.remove(key);
      return null;
    }

    return data['value'] as List<dynamic>;
  }

  // 특정 키 삭제
  Future<void> removeCache(String key) async {
    _memoryCache.remove(key);
    await _prefs.remove(key);
  }

  // 모든 캐시 삭제
  Future<void> clearAll() async {
    _memoryCache.clear();
    await _prefs.clear();
  }

  // 캐시 키 목록
  Set<String> getCacheKeys() {
    return _prefs.getKeys();
  }

  // 오프라인 데이터 저장
  Future<void> saveOfflineData(String endpoint, dynamic data) async {
    final key = 'offline_$endpoint';
    if (data is Map<String, dynamic>) {
      await setCache(key, data);
    } else if (data is List) {
      await setCacheList(key, data);
    }
  }

  // 오프라인 데이터 가져오기
  Future<dynamic> getOfflineData(String endpoint) async {
    final key = 'offline_$endpoint';
    // 먼저 리스트로 시도
    var data = await getCacheList(key);
    if (data != null) return data;

    // Map으로 시도
    return await getCache(key);
  }

  // === 동기화 큐 시스템 ===

  // 동기화 큐에 작업 추가
  Future<void> addToSyncQueue(String id, Map<String, dynamic> operation) async {
    _syncQueue[id] = {
      'operation': operation,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
      'maxRetries': 3,
    };
    await _saveSyncQueue();
  }

  // 동기화 큐 저장
  Future<void> _saveSyncQueue() async {
    await _prefs.setString('sync_queue', jsonEncode(_syncQueue));
  }

  // 동기화 큐 가져오기
  Map<String, dynamic> getSyncQueue() {
    return Map.from(_syncQueue);
  }

  // 동기화 큐에서 작업 제거
  Future<void> removeFromSyncQueue(String id) async {
    _syncQueue.remove(id);
    await _saveSyncQueue();
  }

  // 동기화 실패 시 재시도 횟수 증가
  Future<void> incrementSyncRetry(String id) async {
    if (_syncQueue.containsKey(id)) {
      final item = _syncQueue[id] as Map<String, dynamic>;
      item['retryCount'] = (item['retryCount'] as int) + 1;

      // 최대 재시도 횟수 초과 시 큐에서 제거
      if (item['retryCount'] >= item['maxRetries']) {
        await removeFromSyncQueue(id);
      } else {
        await _saveSyncQueue();
      }
    }
  }

  // === 고급 캐시 기능 ===

  // 캐시 압축 (대용량 데이터용)
  Future<void> setCacheCompressed(String key, dynamic data) async {
    final jsonString = jsonEncode(data);
    final compressedData = gzip.encode(utf8.encode(jsonString));

    final cacheData = {
      'data': base64Encode(compressedData),
      'compressed': true,
      'hash': _generateHash(data),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _prefs.setString('cache_$key', jsonEncode(cacheData));
  }

  // 압축된 캐시 가져오기
  Future<dynamic> getCacheCompressed(String key) async {
    final jsonString = _prefs.getString('cache_$key');
    if (jsonString == null) return null;

    final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
    final timestamp = cacheData['timestamp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;

    // TTL 체크
    if (now - timestamp > diskCacheTTL) {
      await _prefs.remove('cache_$key');
      return null;
    }

    final isCompressed = cacheData['compressed'] as bool? ?? false;
    final dataString = cacheData['data'] as String;

    dynamic data;
    if (isCompressed) {
      final compressedData = base64Decode(dataString);
      final decompressedData = gzip.decode(compressedData);
      data = jsonDecode(utf8.decode(decompressedData));
    } else {
      data = jsonDecode(dataString);
    }

    // 데이터 무결성 검증
    final expectedHash = cacheData['hash'] as String?;
    if (!_verifyDataIntegrity(data, expectedHash)) {
      await _prefs.remove('cache_$key');
      return null;
    }

    return data;
  }

  // 캐시 통계 정보
  Map<String, dynamic> getCacheStats() {
    final keys = _prefs.getKeys();
    final stats = {
      'totalKeys': keys.length,
      'memoryCache': _memoryCache.length,
      'syncQueue': _syncQueue.length,
      'cacheKeys': keys.where((k) => k.startsWith('cache_')).length,
      'offlineKeys': keys.where((k) => k.startsWith('offline_')).length,
    };

    // 캐시 크기 계산 (근사값)
    int totalSize = 0;
    for (final key in keys) {
      final value = _prefs.getString(key);
      if (value != null) {
        totalSize += value.length;
      }
    }
    stats['approximateSize'] = totalSize;

    return stats;
  }

  // 선택적 캐시 정리
  Future<void> clearCacheByPattern(String pattern) async {
    final keys = _prefs.getKeys().where((key) => key.contains(pattern)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }

    // 메모리 캐시에서도 제거
    final memoryKeys = _memoryCache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in memoryKeys) {
      _memoryCache.remove(key);
    }
  }

  // 캐시 우선순위 시스템 (자주 사용되는 데이터 우선 보존)
  Future<void> setCachePriority(String key, dynamic data, {int priority = 1}) async {
    final cacheData = {
      'data': data,
      'priority': priority,
      'accessCount': 1,
      'lastAccessed': DateTime.now().millisecondsSinceEpoch,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'hash': _generateHash(data),
    };

    await _prefs.setString('priority_$key', jsonEncode(cacheData));
  }

  // 우선순위 캐시 가져오기
  Future<dynamic> getCachePriority(String key) async {
    final jsonString = _prefs.getString('priority_$key');
    if (jsonString == null) return null;

    final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
    final timestamp = cacheData['timestamp'] as int;
    final priority = cacheData['priority'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 우선순위에 따른 TTL 조정
    final adjustedTTL = diskCacheTTL * priority;
    if (now - timestamp > adjustedTTL) {
      await _prefs.remove('priority_$key');
      return null;
    }

    // 접근 횟수 증가
    cacheData['accessCount'] = (cacheData['accessCount'] as int) + 1;
    cacheData['lastAccessed'] = now;
    await _prefs.setString('priority_$key', jsonEncode(cacheData));

    final data = cacheData['data'];
    final expectedHash = cacheData['hash'] as String?;

    if (!_verifyDataIntegrity(data, expectedHash)) {
      await _prefs.remove('priority_$key');
      return null;
    }

    return data;
  }
}