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
        error: (e, stack) => const SignInScreen(),
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

// --- State Management ---
final tasksProvider = Provider<List<MatrixTask>>((ref) {
  return [
    MatrixTask(
      id: '1',
      workspaceId: 'w1',
      title: 'Refactor Iceberg Components',
      description: 'Clean up the legacy frost-engine code to improve rendering speed.',
      status: 'To Do',
      priority: 'high',
    ),
    MatrixTask(
      id: '2',
      workspaceId: 'w1',
      title: 'Snowflake Animation Path',
      description: 'Design the delightful physics for the falling snow background effect.',
      status: 'To Do',
      priority: 'normal',
    ),
    MatrixTask(
      id: '3',
      workspaceId: 'w1',
      title: 'Winter Launch Campaign',
      description: 'Finalize the assets for the December 1st announcement.',
      status: 'Ready',
      priority: 'high',
    ),
    MatrixTask(
      id: '4',
      workspaceId: 'w1',
      title: 'Cold-Storage Migration',
      description: 'Moving non-active board data to the glacier-tier server for cost optimization.',
      status: 'WIP',
      priority: 'high',
    ),
  ];
});

// --- UI Components ---

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

class _OracleFeed extends StatelessWidget {
  const _OracleFeed();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.only(bottom: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: const [
          _UpdateCard(
            title: 'Sprint Review Today',
            content: 'The Q4 roadmap review starts at 2:00 PM in the main lounge.',
            icon: Icons.notifications,
            iconBg: Color(0xFFE3F2FD),
            iconColor: SnowscapeColors.primary,
          ),
          _UpdateCard(
            title: 'New UI Guidelines',
            content: "Updated 'Glacier Drift' component library is now live.",
            icon: Icons.star,
            iconBg: Color(0xFFFFF8E1),
            iconColor: Colors.orange,
          ),
          _UpdateCard(
            title: 'Core V2 Deployed',
            content: 'Server migrations are complete. 30% speed boost observed.',
            icon: Icons.celebration,
            iconBg: Color(0xFFE8F5E9),
            iconColor: Colors.green,
          ),
        ],
      ),
    );
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
    final tasksValue = ref.watch(tasksStreamProvider);
    final columns = [
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
                  tasks.where((t) => t.status == column).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _KanbanColumn(
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
            final columnTasks = tasks.where((t) => t.status == column).toList();
            return _KanbanColumn(title: column, tasks: columnTasks);
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

  const _KanbanColumn({required this.title, required this.tasks, this.width});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<MatrixTask>(
      onWillAcceptWithDetails: (details) => details.data.status != title,
      onAcceptWithDetails: (details) async {
        final task = details.data;
        final updatedTask = MatrixTask(
          id: task.id,
          workspaceId: task.workspaceId,
          title: task.title,
          description: task.description,
          status: title,
          priority: task.priority,
          assignedTo: task.assignedTo,
          parentTaskId: task.parentTaskId,
          artifacts: task.artifacts,
        );
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
                    const Icon(Icons.more_horiz,
                        color: SnowscapeColors.onSurfaceVariant),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: width != null ? const NeverScrollableScrollPhysics() : null,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
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
  const _TaskCard({required this.task});

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
