// models/task.dart

class Task {
  final String id;
  final String title;
  final String description;
  final double reward;
  final String status;
  final List<String> skills;
  final DateTime createdAt;
  final DateTime? deadline;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.status,
    required this.skills,
    required this.createdAt,
    this.deadline,
  });

  // JSON 데이터를 Task 객체로 변환하는 factory 생성자
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      reward: double.parse(json['reward'].toString()),
      status: json['status'] as String,
      skills: List<String>.from(json['skills'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
    );
  }
}
