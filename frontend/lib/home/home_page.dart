import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/api_client.dart';

/// Walking-skeleton screen: shows the greeting returned by GET /api/hello.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<String> _greeting = _loadGreeting();

  Future<String> _loadGreeting() async {
    final response = await apiClient.get<Map<String, dynamic>>('/api/hello');
    return response.data!['message'] as String;
  }

  String _describeError(Object error) {
    if (error is DioException && error.response != null) {
      return 'Backend vrátil ${error.response!.statusCode}';
    }
    return 'Backend nie je dostupný: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings Tracker'),
        actions: [
          IconButton(
            tooltip: 'Odhlásiť sa',
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<String>(
          future: _greeting,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(_describeError(snapshot.error!));
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return Text(snapshot.data!, style: Theme.of(context).textTheme.headlineMedium);
          },
        ),
      ),
    );
  }
}
