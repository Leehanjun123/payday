// services/task_service.dart

import 'package:dio/dio.dart';
import '../models/task.dart';

class TaskService {
  // Dio 인스턴스 생성. 실제 앱에서는 싱글톤으로 관리하거나 DI(Dependency Injection)를 사용합니다.
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.45.250:3000/api',
      // 임시 API 키. 실제 앱에서는 Secure Storage에서 관리해야 합니다.
      headers: {
        'X-API-Key': 'temporary-api-key',
      },
    ),
  );

  // 모든 'OPEN' 상태의 작업 목록을 가져옵니다.
  Future<List<Task>> getOpenTasks() async {
    try {
      final response = await _dio.get('/tasks');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> taskData = response.data['data'];
        // JSON 리스트를 Task 객체 리스트로 변환
        return taskData.map((json) => Task.fromJson(json)).toList();
      } else {
        // 서버에서 success: false를 반환하거나, 200이 아닌 상태 코드를 반환한 경우
        throw Exception('Failed to load tasks: Invalid response from server');
      }
    } on DioException catch (e) {
      // Dio 관련 에러 (네트워크, 타임아웃 등) 처리
      // 에러 로깅 또는 사용자에게 보여줄 메시지 포맷팅 등을 할 수 있습니다.
      print('Error fetching tasks: $e');
      throw Exception('Failed to load tasks: ${e.message}');
    } catch (e) {
      // 그 외 알 수 없는 에러
      print('Unknown error: $e');
      throw Exception('An unknown error occurred');
    }
  }

  // 새로운 Task를 생성합니다.
  Future<Task> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.post('/tasks', data: taskData);

      if (response.statusCode == 201 && response.data['success'] == true) {
        // JSON 데이터를 Task 객체로 변환하여 반환
        return Task.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to create task: Invalid response from server');
      }
    } on DioException catch (e) {
      // API에서 보낸 에러 메시지가 있다면 함께 표시합니다.
      final errorMessage = e.response?.data?['msg'] ?? e.message;
      throw Exception('Failed to create task: $errorMessage');
    } catch (e) {
      throw Exception('An unknown error occurred while creating task');
    }
  }

  // 특정 작업에 지원합니다.
  Future<Task> applyForTask(String taskId) async {
    try {
      final response = await _dio.patch('/tasks/$taskId/assign');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Task.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to apply for task: Invalid response');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error'] ?? e.message;
      throw Exception('Failed to apply for task: $errorMessage');
    } catch (e) {
      throw Exception('An unknown error occurred while applying for task');
    }
  }
}
