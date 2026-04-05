// ignore_for_file: avoid_print
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:msp/msp.dart';
import 'theme.dart';
import 'providers.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/new_task_screen.dart';
import 'screens/task_detail_screen.dart';

import 'services/matrix_brain.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env might not exist in all environments, fallback to defaults in provider
  }
  
  runApp(const ProviderScope(child: MatrixHQApp()));
}

class MatrixHQApp extends ConsumerWidget {
  const MatrixHQApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Matrix HQ',
      debugShowCheckedModeBanner: false,
      theme: createHQTheme(),
      home: authState.when(
        data: (isAuthenticated) => isAuthenticated ? const DashboardScreen() : const SignInScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => const SignInScreen(),
      ),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/new-task': (context) => const NewTaskScreen(),
        '/task-detail': (context) => const TaskDetailScreen(),
      },
    );
  }
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matrixBrainProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TopAppBar(),
                const _OracleFeed(),
                Expanded(
                  child: _MatrixKanban(),
                ),
              ],
            ),
          ),
          const _MatrixFAB(),
        ],
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Matrix HQ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: SnowscapeColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
          ),
          Row(
            children: [
              _IconButton(icon: Icons.search),
              const SizedBox(width: 8),
              _IconButton(
                icon: Icons.settings,
                color: SnowscapeColors.primary,
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onPressed;
  const _IconButton({required this.icon, this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SnowscapeColors.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? SnowscapeColors.onSurfaceVariant),
        onPressed: onPressed ?? () {},
      ),
    );
  }
}

class _OracleFeed extends ConsumerWidget {
  const _OracleFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksValue = ref.watch(tasksProvider);

    return Container(
      height: 120,
      padding: const EdgeInsets.only(bottom: 16),
      child: tasksValue.when(
        data: (tasks) {
          final recentTasks = tasks.reversed.take(5).toList();
          if (recentTasks.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Awaiting first prophecy...', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: recentTasks.length,
            itemBuilder: (context, index) {
              final task = recentTasks[index];
              return _UpdateCard(
                title: task.title,
                content: 'Status: ${task.status}',
                icon: _getIconForStatus(task.status),
                iconBg: _getIconBgForStatus(task.status),
                iconColor: _getIconColorForStatus(task.status),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const SizedBox(),
      ),
    );
  }

  IconData _getIconForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft': return Icons.edit_note;
      case 'interpreted': return Icons.auto_awesome;
      case 'complete': return Icons.check_circle;
      default: return Icons.notifications;
    }
  }

  Color _getIconBgForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft': return const Color(0xFFE3F2FD);
      case 'interpreted': return const Color(0xFFFFF8E1);
      case 'complete': return const Color(0xFFE8F5E9);
      default: return const Color(0xFFF5F5F5);
    }
  }

  Color _getIconColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft': return Colors.blue;
      case 'interpreted': return Colors.orange;
      case 'complete': return Colors.green;
      default: return Colors.grey;
    }
  }
}

class _UpdateCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _UpdateCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnowscapeColors.surfaceContainerLowest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(content,
                      style: const TextStyle(
                          fontSize: 12, color: SnowscapeColors.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixKanban extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksValue = ref.watch(tasksProvider);
    final columns = [
      'Draft',
      'Interpreted',
      'Backlog',
      'Architect Review',
      'In Progress',
      'Validation',
      'Complete'
    ];

    final isMobile = MediaQuery.of(context).size.width < 600;

    return tasksValue.when(
      data: (tasks) {
        if (isMobile) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: columns.length,
            itemBuilder: (context, index) {
              final column = columns[index];
              final columnTasks =
                  tasks.where((t) => t.status.toLowerCase() == column.toLowerCase()).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _KanbanColumn(
                  key: ValueKey('column_${column.toLowerCase()}'),
                  title: column,
                  tasks: columnTasks,
                  width: double.infinity,
                ),
              );
            },
          );
        }

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: columns.length,
          separatorBuilder: (context, index) => const SizedBox(width: 24),
          itemBuilder: (context, index) {
            final column = columns[index];
            final columnTasks = tasks.where((t) => t.status.toLowerCase() == column.toLowerCase()).toList();
            return _KanbanColumn(
              key: ValueKey('column_${column.toLowerCase()}'),
              title: column,
              tasks: columnTasks,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading tasks: $err')),
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  final String title;
  final List<MatrixTask> tasks;
  final double? width;

  const _KanbanColumn({super.key, required this.title, required this.tasks, this.width});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<MatrixTask>(
      onWillAcceptWithDetails: (details) => details.data.status != title,
      onAcceptWithDetails: (details) async {
        final task = details.data;
        final updatedTask = task.copyWith(status: title);
        await ref.read(dataProvider).updateTask(updatedTask);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: width ?? 320,
          constraints: width == null ? const BoxConstraints(maxWidth: 320) : null,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? SnowscapeColors.surfaceContainerLow.withValues(alpha: 0.8)
                : SnowscapeColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(32),
            border: candidateData.isNotEmpty
                ? Border.all(color: SnowscapeColors.primary, width: 2)
                : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${tasks.length}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.more_horiz,
                          color: SnowscapeColors.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: width != null ? const NeverScrollableScrollPhysics() : null,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => _TaskCard(
                    key: ValueKey('task_${tasks[index].id}'),
                    task: tasks[index],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor() {
    switch (title) {
      case 'Draft':
        return Colors.blueGrey;
      case 'Interpreted':
        return Colors.purpleAccent;
      case 'Backlog':
        return Colors.grey;
      case 'Architect Review':
        return SnowscapeColors.secondary;
      case 'In Progress':
        return SnowscapeColors.primary;
      case 'Validation':
        return SnowscapeColors.primaryContainer;
      case 'Complete':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}

class _TaskCard extends StatelessWidget {
  final MatrixTask task;
  const _TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SnowscapeColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SnowscapeColors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  task.priority.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: SnowscapeColors.onTertiaryContainer,
                  ),
                ),
              ),
              const Icon(Icons.code, color: Colors.black12),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            task.description,
            style: const TextStyle(
              fontSize: 14,
              color: SnowscapeColors.onSurfaceVariant,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: SnowscapeColors.surfaceContainerLow,
                child: Icon(Icons.person, size: 16, color: Colors.grey),
              ),
              Row(
                children: const [
                  Icon(Icons.folder_outlined, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('core-repo',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return Draggable<MatrixTask>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: SizedBox(
            width: 320,
            child: card,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: card,
      ),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/task-detail', arguments: task),
        child: card,
      ),
    );
  }
}

class _MatrixFAB extends StatelessWidget {
  const _MatrixFAB();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,
      right: 32,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SnowscapeColors.primary, SnowscapeColors.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: SnowscapeColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/new-task'),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
