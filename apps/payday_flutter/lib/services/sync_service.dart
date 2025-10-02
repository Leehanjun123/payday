import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'cache_service.dart';
import 'data_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final CacheService _cache = CacheService();
  final DataService _dataService = DataService();
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = false;
  bool _isSyncing = false;

  // 백그라운드 동기화 간격 (5분)
  static const Duration syncInterval = Duration(minutes: 5);

  Future<void> initialize() async {
    await _setupConnectivityListener();
    _startBackgroundSync();
  }

  // 네트워크 상태 모니터링
  Future<void> _setupConnectivityListener() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = !connectivityResult.contains(ConnectivityResult.none);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = !results.contains(ConnectivityResult.none);

        // 네트워크 연결 복구 시 즉시 동기화
        if (!wasOnline && _isOnline) {
          _performSync();
        }
      },
    );
  }

  // 백그라운드 동기화 시작
  void _startBackgroundSync() {
    _syncTimer = Timer.periodic(syncInterval, (timer) {
      if (_isOnline && !_isSyncing) {
        _performSync();
      }
    });
  }

  // 동기화 수행
  Future<void> _performSync() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;

    try {
      final syncQueue = _cache.getSyncQueue();

      for (final entry in syncQueue.entries) {
        final id = entry.key;
        final item = entry.value as Map<String, dynamic>;
        final operation = item['operation'] as Map<String, dynamic>;

        try {
          await _processSyncOperation(operation);
          await _cache.removeFromSyncQueue(id);
        } catch (e) {
          // 동기화 실패 시 재시도 횟수 증가
          await _cache.incrementSyncRetry(id);
        }
      }

      // 서버에서 최신 데이터 가져오기
      await _syncFromServer();

    } catch (e) {
      // 동기화 실패 시 로그 기록
      print('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // 개별 동기화 작업 처리
  Future<void> _processSyncOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    final data = operation['data'] as Map<String, dynamic>;

    switch (type) {
      case 'create_earning':
        await _dataService.addEarning(
          source: data['source'] ?? '',
          amount: data['amount'] ?? 0.0,
          description: data['description'] ?? '',
        );
        break;
      case 'update_earning':
        await _dataService.updateIncome(
          int.parse(data['id'].toString()),
          title: data['source'],
          amount: data['amount'],
          description: data['description'],
        );
        break;
      case 'delete_earning':
        await _dataService.deleteIncome(int.parse(data['id'].toString()));
        break;
      case 'create_goal':
        await _dataService.createGoal(data);
        break;
      case 'update_goal':
        await _dataService.updateGoal(data['id'], data);
        break;
      case 'delete_goal':
        await _dataService.deleteGoal(data['id']);
        break;
      default:
        throw Exception('Unknown sync operation: $type');
    }
  }

  // 서버에서 데이터 동기화
  Future<void> _syncFromServer() async {
    try {
      // 수익 데이터 동기화
      final earnings = await _dataService.getEarnings();
      await _cache.setCacheList('earnings', earnings);

      // 목표 데이터 동기화
      final goals = await _dataService.getGoals();
      await _cache.setCacheList('goals', goals);

      // 사용자 설정 동기화
      final settings = await _dataService.getUserSettings();
      if (settings != null) {
        await _cache.setCache('user_settings', settings);
      }

    } catch (e) {
      print('Server sync failed: $e');
    }
  }

  // 수동 동기화 트리거
  Future<bool> syncNow() async {
    if (!_isOnline) return false;

    await _performSync();
    return true;
  }

  // 오프라인 작업 큐에 추가
  Future<void> queueOfflineOperation(String type, Map<String, dynamic> data) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final operation = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _cache.addToSyncQueue(id, operation);
  }

  // 충돌 해결 로직
  Future<Map<String, dynamic>?> resolveConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
  ) async {
    final localTimestamp = localData['updatedAt'] as int? ?? 0;
    final serverTimestamp = serverData['updatedAt'] as int? ?? 0;

    // 최신 타임스탬프 우선
    if (localTimestamp > serverTimestamp) {
      return localData;
    } else if (serverTimestamp > localTimestamp) {
      return serverData;
    }

    // 타임스탬프가 같은 경우 서버 데이터 우선
    return serverData;
  }

  // 네트워크 상태 기반 동기화 전략
  SyncStrategy getSyncStrategy() {
    if (!_isOnline) {
      return SyncStrategy.offline;
    }

    // 네트워크 타입에 따른 전략 결정 (향후 구현)
    return SyncStrategy.automatic;
  }

  // 동기화 상태 정보
  Map<String, dynamic> getSyncStatus() {
    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'queueSize': _cache.getSyncQueue().length,
      'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
      'strategy': getSyncStrategy().toString(),
    };
  }

  // 선택적 동기화 (특정 데이터 타입만)
  Future<void> syncSpecificData(String dataType) async {
    if (!_isOnline) return;

    try {
      switch (dataType) {
        case 'earnings':
          final earnings = await _dataService.getEarnings();
          await _cache.setCacheList('earnings', earnings);
          break;
        case 'goals':
          final goals = await _dataService.getGoals();
          await _cache.setCacheList('goals', goals);
          break;
        case 'settings':
          final settings = await _dataService.getUserSettings();
          if (settings != null) {
            await _cache.setCache('user_settings', settings);
          }
          break;
      }
    } catch (e) {
      print('Specific sync failed for $dataType: $e');
    }
  }

  // 동기화 서비스 정리
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }
}

enum SyncStrategy {
  offline,      // 오프라인 모드
  automatic,    // 자동 동기화
  manual,       // 수동 동기화만
  selective,    // 선택적 동기화
}