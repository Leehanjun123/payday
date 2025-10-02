// screens/marketplace/task_list_screen.dart

import 'package:flutter/material.dart';
import '../../services/task_service.dart';
import '../../models/task.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> _tasksFuture;
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    // 화면이 처음 로드될 때 Task 목록을 가져옵니다.
    _tasksFuture = _taskService.getOpenTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마켓플레이스'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          // 로딩 중일 때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 에러가 발생했을 때
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }
          // 데이터가 없거나 비어있을 때
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('현재 의뢰 가능한 작업이 없습니다.'));
          }

          // 데이터 로딩 성공
          final tasks = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskCard(task);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // CreateTaskScreen으로 이동하고, 결과 값을 기다립니다.
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CreateTaskScreen()),
          );

          // 결과가 true이면 (작업 생성 성공), 목록을 새로고침합니다.
          if (result == true) {
            setState(() {
              _tasksFuture = _taskService.getOpenTasks();
            });
          }
        },
        tooltip: '새 작업 의뢰',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Task 정보를 보여주는 카드 위젯
  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (task.skills.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: task.skills.map((skill) => Chip(label: Text(skill))).toList(),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '보상: ${task.reward.toStringAsFixed(0)}원',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
                    );
                    // 상세 화면에서 작업 지원 등 성공적인 액션이 있었으면, 목록을 새로고침합니다.
                    if (result == true) {
                      setState(() {
                        _tasksFuture = _taskService.getOpenTasks();
                      });
                    }
                  },
                  child: const Text('자세히 보기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
