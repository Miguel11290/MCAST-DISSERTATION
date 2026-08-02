import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Text(
          'Inventory & Safety Management System',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          'A research prototype for safety-oriented inventory monitoring in the '
          'Maltese fireworks manufacturing context.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        SizedBox(height: 24),
        _InfoSection(
          title: 'Hybrid safety monitoring',
          body:
              'The system combines deterministic rule-based evaluation, storage '
              'compatibility analysis and Isolation Forest anomaly detection. Rules '
              'identify known conditions; machine learning highlights unusual patterns.',
        ),
        _InfoSection(
          title: 'Regulatory grounding',
          body:
              'Rules are documented against Maltese legislation, EU requirements, '
              'operational guidance and anonymised stakeholder-informed practice. '
              'Configurable values remain prototype parameters until validated for a '
              'specific licensed operating environment.',
        ),
        _InfoSection(
          title: 'Decision-support disclaimer',
          body:
              'The artefact does not replace licensed pyrotechnicians, approved '
              'procedures, competent authorities or professional safety judgement.',
        ),
        _InfoSection(
          title: 'Technology',
          body:
              'Flutter frontend, FastAPI backend, SQLAlchemy/SQLite persistence and '
              'Scikit-learn Isolation Forest anomaly detection.',
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String body;

  const _InfoSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }
}
