import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msp/msp.dart';
import '../theme.dart';

class TaskDetailScreen extends StatelessWidget {
  final MatrixTask? task;

  const TaskDetailScreen({super.key, this.task});

  @override
  Widget build(BuildContext context) {
    // If task is null, try to get it from arguments (for named routes)
    final effectiveTask = task ?? ModalRoute.of(context)?.settings.arguments as MatrixTask?;

    if (effectiveTask == null) {
      return const Scaffold(
        body: Center(child: Text('No task selected')),
      );
    }

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
                _buildChip(effectiveTask.status.toUpperCase(), SnowscapeColors.onTertiaryContainer, SnowscapeColors.tertiaryContainer, icon: Icons.pending_outlined),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              effectiveTask.title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    height: 1.1,
                  ),
            ),
            const SizedBox(height: 40),
            _buildSection(
              icon: Icons.description,
              title: 'Full Document (Markdown)',
              color: SnowscapeColors.primary,
              child: MarkdownBody(
                data: effectiveTask.content ?? effectiveTask.synthesizeContent(),
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: SnowscapeColors.onSurfaceVariant,
                    height: 1.6,
                  ),
                  h1: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: SnowscapeColors.onSurface,
                  ),
                  code: GoogleFonts.jetBrainsMono(
                    backgroundColor: SnowscapeColors.surfaceContainerLow,
                    fontSize: 14,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: SnowscapeColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              icon: Icons.account_tree_outlined,
              title: 'Metadata Summary',
              color: SnowscapeColors.secondary,
              child: Column(
                children: [
                  _buildMetadataRow('Status', effectiveTask.status),
                  _buildMetadataRow('Priority', effectiveTask.priority),
                  _buildMetadataRow('Assigned To', effectiveTask.assignedTo ?? 'Unassigned'),
                  if (effectiveTask.parentTaskId != null)
                    _buildMetadataRow('Parent Task', effectiveTask.parentTaskId!),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: SnowscapeColors.onSurfaceVariant)),
          Text(value, style: const TextStyle(color: SnowscapeColors.onSurface)),
        ],
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
}
