import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../services/passive_income_factory.dart';

class DeveloperSettingsScreen extends StatefulWidget {
  @override
  _DeveloperSettingsScreenState createState() => _DeveloperSettingsScreenState();
}

class _DeveloperSettingsScreenState extends State<DeveloperSettingsScreen> {
  AppEnvironment _selectedEnvironment = EnvironmentConfig.current;

  void _changeEnvironment(AppEnvironment env) {
    setState(() {
      _selectedEnvironment = env;
      EnvironmentConfig.setEnvironment(env);
      PassiveIncomeFactory.switchEnvironment(env);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Environment switched to ${env.name}'),
        backgroundColor: _getEnvironmentColor(env),
      ),
    );
  }

  Color _getEnvironmentColor(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.mock:
        return Colors.orange;
      case AppEnvironment.staging:
        return Colors.blue;
      case AppEnvironment.production:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🛠️ Developer Settings'),
        backgroundColor: Colors.grey[900],
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '환경 설정',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '현재 환경: ${_selectedEnvironment.name.toUpperCase()}',
                      style: TextStyle(
                        color: _getEnvironmentColor(_selectedEnvironment),
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildEnvironmentOption(
                      AppEnvironment.mock,
                      '🎭 Mock Data',
                      '로컬 목업 데이터 사용 (오프라인 개발용)',
                    ),
                    _buildEnvironmentOption(
                      AppEnvironment.staging,
                      '🔧 Staging',
                      'Railway 스테이징 서버 연결',
                    ),
                    _buildEnvironmentOption(
                      AppEnvironment.production,
                      '🚀 Production',
                      'Railway 프로덕션 서버 연결',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API 정보',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow('Base URL', EnvironmentConfig.apiBaseUrl),
                    _buildInfoRow('Use Mock Data', EnvironmentConfig.useMockData.toString()),
                    _buildInfoRow('Use Real Ads', EnvironmentConfig.useRealAds.toString()),
                    _buildInfoRow('Use Real Payments', EnvironmentConfig.useRealPayments.toString()),
                    _buildInfoRow('Use Real Passive Income', EnvironmentConfig.useRealPassiveIncome.toString()),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              color: Colors.amber[900],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Production 환경은 실제 데이터를 사용합니다.\n변경 시 주의하세요!',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentOption(AppEnvironment env, String title, String subtitle) {
    final isSelected = _selectedEnvironment == env;
    final color = _getEnvironmentColor(env);

    return ListTile(
      leading: Radio<AppEnvironment>(
        value: env,
        groupValue: _selectedEnvironment,
        onChanged: (value) => _changeEnvironment(value!),
        activeColor: color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? color : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
      onTap: () => _changeEnvironment(env),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}