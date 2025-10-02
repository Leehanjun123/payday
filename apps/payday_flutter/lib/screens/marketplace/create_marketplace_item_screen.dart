// screens/marketplace/create_marketplace_item_screen.dart

import 'package:flutter/material.dart';
import '../../services/marketplace_service.dart';

class CreateMarketplaceItemScreen extends StatefulWidget {
  const CreateMarketplaceItemScreen({Key? key}) : super(key: key);

  @override
  _CreateMarketplaceItemScreenState createState() => _CreateMarketplaceItemScreenState();
}

class _CreateMarketplaceItemScreenState extends State<CreateMarketplaceItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();

  final _marketplaceService = MarketplaceService();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final itemData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'category': _categoryController.text,
        };

        await _marketplaceService.createItem(itemData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('재능 상품이 성공적으로 등록되었습니다.')),
          );
          Navigator.of(context).pop(true); // 성공 시 true 반환
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('등록 실패: $e')),
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
        title: const Text('새 재능 등록'),
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
                labelText: '재능 제목',
                hintText: '예: 40분만에 웹사이트 만들어 드립니다',
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _descriptionController,
                labelText: '상세 설명',
                hintText: '재능에 대한 구체적인 내용을 적어주세요.',
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _priceController,
                labelText: '가격 (원)',
                hintText: '예: 100000',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _categoryController,
                labelText: '카테고리',
                hintText: '예: 개발, 디자인, 번역',
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
                    : const Text('내 재능 판매 시작하기'),
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
        if (labelText.contains('가격') && double.tryParse(value) == null) {
          return '숫자만 입력해주세요.';
        }
        return null;
      },
    );
  }
}
