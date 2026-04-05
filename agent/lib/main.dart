import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rust/rust.dart';
import 'theme.dart';
import 'providers.dart';
import 'screens/sign_in_screen.dart';
import 'screens/settings_screen.dart';
import 'services/autonomous_loop.dart';

// Log state provider using Notifier
class LogsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [
        '> System initialized...',
        '> Connected to Matrix HQ...',
        '> Awaiting prophecies...',
      ];

  void addLog(String log) {
    state = [...state, log];
  }
}

final logsProvider = NotifierProvider<LogsNotifier, List<String>>(LogsNotifier.new);

// Capability state provider
class CapabilitiesNotifier extends Notifier<List<HardwareDevice>> {
  @override
  List<HardwareDevice> build() => [];

  void setCapabilities(String report) {
    // Basic parser for the markdown report
    final lines = report
        .split('\n')
        .where((l) => l.startsWith('- '))
        .map((l) => l.replaceFirst('- ', '').replaceAll('**', ''))
        .toList();
    
    state = lines.map((l) => HardwareDevice(
      id: l,
      name: l,
      connectionType: 'System',
      status: 'Available',
    )).toList();
  }

  void setDevices(List<HardwareDevice> devices) {
    state = devices;
  }
}

final capabilitiesProvider = NotifierProvider<CapabilitiesNotifier, List<HardwareDevice>>(CapabilitiesNotifier.new);

// Worktree state provider
class WorktreeNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setWorktree(String? path) {
    state = path;
  }
}

final worktreeProvider = NotifierProvider<WorktreeNotifier, String?>(WorktreeNotifier.new);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env might not exist
  }
  runApp(const ProviderScope(child: MatrixAgentApp()));
}

class MatrixAgentApp extends ConsumerWidget {
  const MatrixAgentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Matrix Agent',
      debugShowCheckedModeBanner: false,
      theme: createAgentTheme(),
      home: authState.when(
        data: (isAuthenticated) => isAuthenticated ? const OperatorDashboard() : const SignInScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, stack) => const SignInScreen(),
      ),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/dashboard': (context) => const OperatorDashboard(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class OperatorDashboard extends ConsumerStatefulWidget {
  const OperatorDashboard({super.key});

  @override
  ConsumerState<OperatorDashboard> createState() => _OperatorDashboardState();
}

class _OperatorDashboardState extends ConsumerState<OperatorDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(autonomousLoopProvider).start();
    });
  }

  Future<void> _scanSystem() async {
    ref.read(logsProvider.notifier).addLog('> Initiating system scan...');
    try {
      final report = await scanSystem();
      ref.read(capabilitiesProvider.notifier).setCapabilities(report);
      ref.read(logsProvider.notifier).addLog('> Scan complete. Capabilities synthesized.');
      ref.read(logsProvider.notifier).addLog(report);
    } catch (e) {
      ref.read(logsProvider.notifier).addLog('> Scan error: $e');
    }
  }

  Future<void> _autoCapabilityCheck() async {
    ref.read(logsProvider.notifier).addLog('> Starting automatic capability check...');
    try {
      final report = await automaticCapabilityCheck();
      ref.read(logsProvider.notifier).addLog('> Automatic check complete.');
      ref.read(logsProvider.notifier).addLog(report);

      // Also update capabilities list if we found something useful
      if (report.contains('AVAILABLE')) {
        await _scanSystem();
      }
    } catch (e) {
      ref.read(logsProvider.notifier).addLog('> Auto-check error: $e');
    }
  }

  Future<void> _runAgent() async {
    final settings = ref.read(modelSettingsProvider);
    final logs = ref.read(logsProvider.notifier);
    final rust = ref.read(rustProvider);

    if (settings.selectedModel == 'Coding Agents' &&
        settings.selectedCodingAgent == 'Gemini CLI') {
      logs.addLog('> Starting Gemini CLI Agent...');
      logs.addLog('> Running: gemini --yolo -p "hi"');
      try {
        // Execute the command via Rust core and listen to stream
        rust.executeCommand(cmd: 'gemini --yolo -p "hi"').listen((log) {
          logs.addLog(log);
        }, onError: (e) {
          logs.addLog('> Error: $e');
        });
      } catch (e) {
        logs.addLog('> Error starting agent: $e');
      }
    } else {
      String modelName = settings.selectedModel;
      if (modelName == 'Coding Agents') {
        modelName = settings.selectedCodingAgent;
      } else if (modelName == 'Cloud Model') {
        modelName = settings.selectedCloudModel;
      }
      logs.addLog('> [$modelName] Not implemented yet.');
    }
  }

  Future<void> _refreshHardware() async {
    final rust = ref.read(rustProvider);
    final caps = ref.read(capabilitiesProvider.notifier);
    final logs = ref.read(logsProvider.notifier);
    
    logs.addLog('> Refreshing hardware status...');
    try {
      final devices = await rust.listHardwareDevices();
      caps.setDevices(devices);
      logs.addLog('> Hardware status updated: ${devices.length} entries.');
    } catch (e) {
      logs.addLog('> Hardware refresh error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logsProvider);
    final capabilities = ref.watch(capabilitiesProvider);
    final activeWorktree = ref.watch(worktreeProvider);

    return Scaffold(
      backgroundColor: SnowscapeColors.surface,
      appBar: AppBar(
        backgroundColor: SnowscapeColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Operator Dashboard',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: SnowscapeColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fact_check_outlined, color: SnowscapeColors.primary),
            tooltip: 'Auto Capability Check',
            onPressed: _autoCapabilityCheck,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: SnowscapeColors.secondary),
            tooltip: 'Scan System',
            onPressed: _scanSystem,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            tooltip: 'Run Agent/Command',
            onPressed: _runAgent,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: SnowscapeColors.primary),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Capability Explorer (Sidebar)
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 8, 12, 24),
              decoration: BoxDecoration(
                color: SnowscapeColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Capabilities',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        _IconButtonSmall(
                          icon: Icons.refresh,
                          onPressed: _refreshHardware,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: capabilities.isEmpty
                        ? const Center(
                            child: Text(
                              'No capabilities discovered.\nTap search to scan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: capabilities.length,
                            itemBuilder: (context, index) {
                              return _buildCapabilityTile(capabilities[index]);
                            },
                          ),
                  ),
                  if (activeWorktree != null) ...[
                    const Divider(indent: 24, endIndent: 24),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Worktree',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: SnowscapeColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: SnowscapeColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              activeWorktree,
                              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Log Stream (Main View)
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 24, 24),
              decoration: BoxDecoration(
                color: SnowscapeColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: SnowscapeColors.onSurface.withValues(alpha: 0.04),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Stream',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, color: Colors.green, size: 8),
                            const SizedBox(width: 8),
                            const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SnowscapeColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        reverse: true,
                        child: SelectableText(
                          logs.join('\n'),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            color: SnowscapeColors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityTile(HardwareDevice device) {
    IconData icon = Icons.check_circle_outline;
    Color statusColor = Colors.green;

    if (device.connectionType == 'ADB') {
      icon = Icons.android;
    } else if (device.connectionType == 'USB') {
      icon = Icons.usb;
    }

    if (device.status.toLowerCase().contains('offline') || 
        device.status.toLowerCase().contains('unauthorized')) {
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnowscapeColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: SnowscapeColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${device.connectionType} • ${device.id}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              device.status.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButtonSmall extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButtonSmall({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: SnowscapeColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16, color: SnowscapeColors.primary),
        onPressed: onPressed,
      ),
    );
  }
}
