import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedPersona = 'The Architect';
  bool _heartbeatEnabled = true;
  String _selectedModel = 'OpenAI API';

  @override
  Widget build(BuildContext context) {
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
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildPersonaButton('The Architect', Icons.architecture),
                _buildPersonaButton('The Oracle', Icons.auto_awesome),
                _buildPersonaButton('Agent', Icons.smart_toy),
                _buildPersonaButton('Sentinel', Icons.shield),
              ],
            ),
            const SizedBox(height: 32),
            _buildHeartbeatCard(),
            const SizedBox(height: 32),
            _buildSectionHeader(Icons.dns, 'Model Selection'),
            const SizedBox(height: 16),
            _buildModelOption('OpenAI API', Icons.cloud_done),
            const SizedBox(height: 12),
            _buildModelOption('Local Model', Icons.storage),
            const SizedBox(height: 12),
            _buildModelOption('Cloud Model', Icons.foggy),
            const SizedBox(height: 40),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? SnowscapeColors.primaryContainer.withValues(alpha: 0.2)
                    : SnowscapeColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? SnowscapeColors.primary : SnowscapeColors.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? SnowscapeColors.primary : SnowscapeColors.onSurfaceVariant,
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

  Widget _buildModelOption(String name, IconData icon) {
    final isSelected = _selectedModel == name;
    return InkWell(
      onTap: () => setState(() => _selectedModel = name),
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
              groupValue: _selectedModel,
              // ignore: deprecated_member_use
              onChanged: (val) => setState(() => _selectedModel = val!),
              activeColor: SnowscapeColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
