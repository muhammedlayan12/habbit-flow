import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/task_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/item_widgets.dart';
import 'create_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Today'), Tab(text: 'Upcoming'), Tab(text: 'Completed')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateTaskScreen())),
          ),
        ],
      ),
      body: taskProvider.isLoading
          ? const LoadingView()
          : TabBarView(
              controller: _tabController,
              children: [
                _TaskList(
                  tasks: taskProvider.todayTasks,
                  emptyTitle: 'Nothing due today',
                  emptyMessage: 'Enjoy the clear schedule, or add something new.',
                ),
                _TaskList(
                  tasks: taskProvider.upcomingTasks,
                  emptyTitle: 'No upcoming tasks',
                  emptyMessage: 'Plan ahead by adding a task with a future due date.',
                ),
                _TaskList(
                  tasks: taskProvider.completedTasks,
                  emptyTitle: 'No completed tasks yet',
                  emptyMessage: 'Completed tasks will show up here.',
                ),
              ],
            ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List tasks;
  final String emptyTitle;
  final String emptyMessage;

  const _TaskList({required this.tasks, required this.emptyTitle, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    if (tasks.isEmpty) {
      return EmptyState(
        icon: Icons.task_alt_outlined,
        title: emptyTitle,
        message: emptyMessage,
        actionLabel: 'Add Task',
        onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateTaskScreen())),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        final userId = taskProvider.tasks.isNotEmpty ? taskProvider.tasks.first.userId : null;
        if (userId != null) await taskProvider.loadForUser(userId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: tasks.length,
        itemBuilder: (context, i) {
          final task = tasks[i];
          return TaskTile(
            task: task,
            onToggle: () => taskProvider.toggleComplete(task.id),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateTaskScreen(existing: task))),
            onDelete: () => taskProvider.deleteTask(task.id),
          );
        },
      ),
    );
  }
}
