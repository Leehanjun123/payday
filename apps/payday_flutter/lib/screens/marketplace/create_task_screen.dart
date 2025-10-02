import 'package:flutter/material.dart';
import '../../services/task_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({Key? key}) : super(key: key);

  @override
  _CreateTaskScreenState createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rewardController = TextEditingController();
  final _skillsController = TextEditingController();

  final _taskService = TaskService();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final skillsList = _skillsController.text.split(',').map((s) => s.trim()).toList();

        final taskData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'reward': double.tryParse(_rewardController.text) ?? 0.0,
          'skills': skillsList,
        };

        await _taskService.createTask(taskData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('새로운 작업이 성공적으로 등록되었습니다.')),
          );
          // 작업 등록 성공 시, true 값을 가지고 이전 화면으로 돌아갑니다.
          Navigator.of(context).pop(true);
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('작업 등록 실패: $e')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 작업 의뢰'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField(
                controller: _titleController,
                labelText: '제목',
                hintText: '예: 간단한 로고 디자인',
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _descriptionController,
                labelText: '상세 설명',
                hintText: '작업에 대한 구체적인 내용을 적어주세요.',
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _rewardController,
                labelText: '보상 (원)',
                hintText: '예: 50000',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _skillsController,
                labelText: '필요 스킬',
                hintText: '쉼표(,)로 구분하여 입력하세요. 예: Photoshop, Illustrator',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('의뢰 등록하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$labelText 항목은 필수입니다.';
        }
        if (labelText == '보상 (원)' && double.tryParse(value) == null) {
          return '숫자만 입력해주세요.';
        }
        return null;
      },
    );
  }
}
