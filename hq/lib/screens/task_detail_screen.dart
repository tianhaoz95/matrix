import 'package:flutter/material.dart';
import '../theme.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnowscapeColors.surface,
      appBar: AppBar(
        backgroundColor: SnowscapeColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SnowscapeColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: const [
            Text(
              'Yukika',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: SnowscapeColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: SnowscapeColors.primary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildChip('CORE APP', SnowscapeColors.secondary, SnowscapeColors.surfaceContainerLow),
                const SizedBox(width: 8),
                _buildChip('WIP', SnowscapeColors.onTertiaryContainer, SnowscapeColors.tertiaryContainer, icon: Icons.pending_outlined),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Refactor Iceberg Components',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    height: 1.1,
                  ),
            ),
            const SizedBox(height: 40),
            _buildSection(
              icon: Icons.subject,
              title: 'Description',
              color: SnowscapeColors.primary,
              child: const Text(
                'Clean up the legacy frost-engine code to improve rendering speed and ensure compatibility with the new snowflake animation engine. This is a high-priority task for the Q4 release.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: SnowscapeColors.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSection(
                    icon: Icons.terminal,
                    title: 'Repository',
                    color: SnowscapeColors.secondary,
                    child: InkWell(
                      onTap: () {},
                      child: const Text(
                        'github.com/yukika/iceberg-refactor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: SnowscapeColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              icon: Icons.account_tree_outlined,
              title: 'Dependencies',
              color: SnowscapeColors.secondary,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDependencyChip('Glacier Asset Audit'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color textColor, Color bgColor, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SnowscapeColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SnowscapeColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDependencyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SnowscapeColors.onSurfaceVariant.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link, size: 14, color: SnowscapeColors.secondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: SnowscapeColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
