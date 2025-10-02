import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _taskService = TaskService();
  bool _isLoading = false;

  Future<void> _applyForTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.applyForTask(widget.task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('작업 지원이 완료되었습니다.')),
        );
        // 성공 시, 목록 화면으로 돌아가서 새로고침 할 수 있도록 true 전달
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('작업 지원 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('작업 상세 정보'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '등록일: ${DateFormat('yyyy년 MM월 dd일').format(widget.task.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const Divider(height: 32),
            _buildSectionTitle(context, '상세 설명'),
            const SizedBox(height: 8),
            Text(
              widget.task.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, '필요 스킬'),
            const SizedBox(height: 8),
            if (widget.task.skills.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: widget.task.skills.map((skill) => Chip(label: Text(skill))).toList(),
              )
            else
              Text('특별히 요구되는 스킬이 없습니다.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            _buildSectionTitle(context, '보상'),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat('#,###').format(widget.task.reward)}원',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _applyForTask,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: _isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
              : const Text('이 작업 지원하기'),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
