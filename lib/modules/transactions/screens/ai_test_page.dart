import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../widgets/ai_test_widget.dart';

/// AI Test Sayfası - Hızlı Test İçin
class AITestPage extends StatelessWidget {
  const AITestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: '🤖 AI Test',
      subtitle: 'Gemini AI\'yi test et',
      body: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 16),
          const AITestWidget(),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }
}

