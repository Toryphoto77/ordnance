import 'package:flutter/material.dart';

import '../i18n.dart';
import '../widgets/app_top_bar.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SubPageAppBar(title: tr('community_guidelines_title')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr('community_guidelines_body'),
              style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }
}
