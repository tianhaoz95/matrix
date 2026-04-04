import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedPersona = 'The Architect';
  bool _heartbeatEnabled = true;
  late TextEditingController _openAiUrlController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(modelSettingsProvider);
    _openAiUrlController = TextEditingController(text: settings.openAiUrl);
  }

  @override
  void dispose() {
    _openAiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(modelSettingsProvider);

    return Scaffold(
      backgroundColor: SnowscapeColors.surface,
      appBar: AppBar(
        backgroundColor: SnowscapeColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SnowscapeColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Program Config',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: SnowscapeColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.psychology, 'Persona Selector'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildPersonaButton('The Architect', Icons.architecture)),
                const SizedBox(width: 8),
                Expanded(child: _buildPersonaButton('The Oracle', Icons.auto_awesome)),
                const SizedBox(width: 8),
                Expanded(child: _buildPersonaButton('Agent', Icons.smart_toy)),
                const SizedBox(width: 8),
                Expanded(child: _buildPersonaButton('Sentinel', Icons.shield)),
              ],
            ),
            const SizedBox(height: 32),
            _buildHeartbeatCard(),
            const SizedBox(height: 32),
            _buildSectionHeader(Icons.dns, 'Model Selection'),
            const SizedBox(height: 16),
            _buildModelOption('OpenAI API', Icons.cloud_done, settings.selectedModel),
            if (settings.selectedModel == 'OpenAI API') ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: TextField(
                  controller: _openAiUrlController,
                  onChanged: (val) => ref.read(modelSettingsProvider.notifier).updateOpenAiUrl(val),
                  decoration: InputDecoration(
                    labelText: 'API URL',
                    hintText: 'https://api.openai.com/v1',
                    filled: true,
                    fillColor: SnowscapeColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.link, size: 20),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildModelOption('Local Model', Icons.storage, settings.selectedModel),
            const SizedBox(height: 12),
            _buildModelOption('Cloud Model', Icons.foggy, settings.selectedModel),
            if (settings.selectedModel == 'Cloud Model') ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_queue,
                        color: SnowscapeColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Select Gemini Model',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: SnowscapeColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  children: [
                    _buildSubOption('Gemini 3 Flash', Icons.bolt,
                        settings.selectedCloudModel, (val) => ref.read(modelSettingsProvider.notifier).updateCloudModel(val)),
                    const SizedBox(height: 8),
                    _buildSubOption('Gemini 3 Pro', Icons.auto_awesome,
                        settings.selectedCloudModel, (val) => ref.read(modelSettingsProvider.notifier).updateCloudModel(val)),
                    const SizedBox(height: 8),
                    _buildSubOption('Gemini 3 Flash Lite', Icons.shutter_speed,
                        settings.selectedCloudModel, (val) => ref.read(modelSettingsProvider.notifier).updateCloudModel(val)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildModelOption('Coding Agents', Icons.code, settings.selectedModel),
            if (settings.selectedModel == 'Coding Agents') ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.integration_instructions,
                        color: SnowscapeColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Select Agent',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: SnowscapeColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  children: [
                    _buildSubOption('Gemini CLI', Icons.terminal, settings.selectedCodingAgent,
                        (val) => ref.read(modelSettingsProvider.notifier).updateCodingAgent(val)),
                    const SizedBox(height: 8),
                    _buildSubOption(
                        'Claude Code',
                        Icons.data_object,
                        settings.selectedCodingAgent,
                        (val) => ref.read(modelSettingsProvider.notifier).updateCodingAgent(val)),
                    const SizedBox(height: 8),
                    _buildSubOption('Codex', Icons.menu_book, settings.selectedCodingAgent,
                        (val) => ref.read(modelSettingsProvider.notifier).updateCodingAgent(val)),
                    const SizedBox(height: 8),
                    _buildSubOption('Kiro', Icons.bolt, settings.selectedCodingAgent,
                        (val) => ref.read(modelSettingsProvider.notifier).updateCodingAgent(val)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSubOption(
      String name, IconData icon, String groupValue, Function(String) onChanged) {
    final isSelected = groupValue == name;
    return InkWell(
      onTap: () => onChanged(name),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? SnowscapeColors.primary.withValues(alpha: 0.05)
              : SnowscapeColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? SnowscapeColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected
                    ? SnowscapeColors.primary
                    : SnowscapeColors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? SnowscapeColors.onSurface
                      : SnowscapeColors.onSurfaceVariant,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  size: 18, color: SnowscapeColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: SnowscapeColors.secondary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: SnowscapeColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonaButton(String name, IconData icon) {
    final isSelected = _selectedPersona == name;
    return InkWell(
      onTap: () => setState(() => _selectedPersona = name),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: SnowscapeColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? SnowscapeColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SnowscapeColors.primary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? SnowscapeColors.primaryContainer.withValues(alpha: 0.2)
                    : SnowscapeColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? SnowscapeColors.primary
                    : SnowscapeColors.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? SnowscapeColors.primary
                      : SnowscapeColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartbeatCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SnowscapeColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: SnowscapeColors.error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Heartbeat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SnowscapeColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Keeps the AI connection warm for instant responses during heavy drift periods.',
                  style: TextStyle(
                    fontSize: 13,
                    color: SnowscapeColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: _heartbeatEnabled,
            onChanged: (val) => setState(() => _heartbeatEnabled = val),
            activeThumbColor: SnowscapeColors.primary,
            activeTrackColor: SnowscapeColors.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildModelOption(String name, IconData icon, String groupValue) {
    final isSelected = groupValue == name;
    return InkWell(
      onTap: () => ref.read(modelSettingsProvider.notifier).updateModel(name),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SnowscapeColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SnowscapeColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SnowscapeColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? SnowscapeColors.primary : SnowscapeColors.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: SnowscapeColors.onSurface,
                ),
              ),
            ),
            Radio<String>(
              value: name,
              // ignore: deprecated_member_use
              groupValue: groupValue,
              // ignore: deprecated_member_use
              onChanged: (val) => ref.read(modelSettingsProvider.notifier).updateModel(val!),
              activeColor: SnowscapeColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
