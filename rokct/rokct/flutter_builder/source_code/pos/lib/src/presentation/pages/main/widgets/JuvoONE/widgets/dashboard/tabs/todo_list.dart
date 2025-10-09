import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../../../core/di/injection.dart';
import '../../../../../../../../core/utils/utils.dart';
import '../../../../../../../components/custom_scaffold.dart';
import '../../../../../../../theme/theme.dart';
import '../providers/task_provider.dart';
import '../models/todo_task.dart';
import '../widgets/add_task_dialog.dart';

class TodoTasksScreen extends StatefulWidget {
  final String? shopId;

  const TodoTasksScreen({super.key, this.shopId});

  @override
  _TodoTasksScreenState createState() => _TodoTasksScreenState();
}

class _TodoTasksScreenState extends State<TodoTasksScreen> {
  late TaskProvider _taskProvider;
  String _selectedFilter = 'All';
  String _selectedSort = 'Due Date';

  @override
  void initState() {
    super.initState();

    // Determine shop ID
    final effectiveShopId = widget.shopId ?? LocalStorage.getUser()?.shop?.id?.toString();

    if (kDebugMode) {
      print('Initializing TodoTasksScreenState');
      print('Passed Shop ID: ${widget.shopId}');
      print('User Shop ID: ${LocalStorage.getUser()?.shop?.id}');
      print('Effective Shop ID: $effectiveShopId');
    }

    _taskProvider = inject<TaskProvider>();

    // Fetch tasks when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskProvider.fetchTasks(widget.shopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
    backgroundColor: AppStyle.white,
    body: (colors) => ChangeNotifierProvider.value(
    value: _taskProvider,
    child: Consumer<TaskProvider>(
    builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (taskProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${taskProvider.error}',
                    style: const TextStyle(color: AppStyle.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => taskProvider.fetchTasks(widget.shopId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final filteredTasks = _getFilteredTasks(taskProvider.tasks);

          if (filteredTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No tasks found',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddTaskDialog(context),
                    child: const Text('Create Task'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Chip(
                      label: Text('Filter: $_selectedFilter'),
                      deleteIcon: const Icon(Icons.clear),
                      onDeleted: _selectedFilter == 'All' ? null : () {
                        setState(() {
                          _selectedFilter = 'All';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('Sort: $_selectedSort'),
                      backgroundColor: AppStyle.accentColor.withOpacity(0.1),
                    ),
                    Spacer(),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: AppStyle.black),
                      onPressed: _showFilterDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort, color: AppStyle.black),
                      onPressed: _showSortDialog,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskItem(filteredTasks[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),floatingActionButton: (colors) => FloatingActionButton(
      onPressed: () => _showAddTaskDialog(context),
      backgroundColor: AppStyle.accentColor,
      child: const Icon(Icons.add)),
    );

  }

  List<TodoTask> _getFilteredTasks(List<TodoTask> tasks) {
    // Apply status filter
    List<TodoTask> filtered = [];

    if (_selectedFilter == 'All') {
      filtered = List.from(tasks);
    } else {
      filtered = tasks.where((task) => task.status == _selectedFilter).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'Due Date':
        // Handle null due dates
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);

        case 'Priority':
        // Convert priority to numeric value for sorting
          int getPriorityValue(String priority) {
            switch (priority) {
              case 'Urgent': return 0;
              case 'High': return 1;
              case 'Medium': return 2;
              case 'Low': return 3;
              default: return 4;
            }
          }
          return getPriorityValue(a.priority).compareTo(getPriorityValue(b.priority));

        case 'Title':
          return a.title.compareTo(b.title);

        default:
          return 0;
      }
    });

    return filtered;
  }

  Widget _buildTaskItem(TodoTask task) {
    Color statusColor;
    switch (task.status) {
      case 'Todo':
        statusColor = AppStyle.grey;
        break;
      case 'In Progress':
        statusColor = AppStyle.blue;
        break;
      case 'Done':
        statusColor = AppStyle.green;
        break;
      case 'Blocked':
        statusColor = AppStyle.red;
        break;
      default:
        statusColor = AppStyle.grey;
    }

    Color priorityColor;
    switch (task.priority) {
      case 'Urgent':
        priorityColor = AppStyle.red;
        break;
      case 'High':
        priorityColor = AppStyle.orange;
        break;
      case 'Medium':
        priorityColor = Colors.yellow.shade800;
        break;
      case 'Low':
        priorityColor = AppStyle.green;
        break;
      default:
        priorityColor = AppStyle.grey;
    }

    bool isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != 'Done';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _editTask(task),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusDot(statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: task.status == 'Done' ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.priority,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 8),
                  child: Text(
                    task.description!,
                    style: TextStyle(
                      color: AppStyle.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 8),
                child: Row(
                  children: [
                    if (task.dueDate != null) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isOverdue ? AppStyle.red : AppStyle.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                        style: TextStyle(
                          color: isOverdue ? AppStyle.red : AppStyle.grey[600],
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isOverdue)
                        Text(
                          ' (Overdue)',
                          style: TextStyle(
                            color: AppStyle.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                    ],
                    if (task.assignedTo != null) ...[
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.person,
                        size: 14,
                        color: AppStyle.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Assigned', // Ideally show the user's name here
                        style: TextStyle(
                          color: AppStyle.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (task.appId != null) ...[
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.phone_android,
                        size: 14,
                        color: AppStyle.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.roadmapVersion != null
                            ? 'App v${task.roadmapVersion}'
                            : 'App Task',
                        style: TextStyle(
                          color: AppStyle.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 12),
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Mark Done',
                      onTap: () => _updateTaskStatus(task, 'Done'),
                      enabled: task.status != 'Done',
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      icon: Icons.play_arrow,
                      label: 'Start',
                      onTap: () => _updateTaskStatus(task, 'In Progress'),
                      enabled: task.status == 'Todo' || task.status == 'Blocked',
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      icon: Icons.block,
                      label: 'Block',
                      onTap: () => _updateTaskStatus(task, 'Blocked'),
                      enabled: task.status != 'Blocked' && task.status != 'Done',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppStyle.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppStyle.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Tasks By Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('All'),
              _buildFilterOption('Todo'),
              _buildFilterOption('In Progress'),
              _buildFilterOption('Done'),
              _buildFilterOption('Blocked'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
            backgroundColor: AppStyle.white
        );
      },
    );
  }

  Widget _buildFilterOption(String filter) {
    return ListTile(
      title: Text(filter),
      leading: Radio<String>(
        value: filter,
        groupValue: _selectedFilter,
        onChanged: (String? value) {
          setState(() {
            _selectedFilter = value!;
          });
          Navigator.of(context).pop();
        },
      ),
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        Navigator.of(context).pop();
      },
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sort Tasks By'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption('Due Date'),
              _buildSortOption('Priority'),
              _buildSortOption('Title'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
            backgroundColor: AppStyle.white
        );
      },
    );
  }

  Widget _buildSortOption(String sort) {
    return ListTile(
      title: Text(sort),
      leading: Radio<String>(
        value: sort,
        groupValue: _selectedSort,
        onChanged: (String? value) {
          setState(() {
            _selectedSort = value!;
          });
          Navigator.of(context).pop();
        },
      ),
      onTap: () {
        setState(() {
          _selectedSort = sort;
        });
        Navigator.of(context).pop();
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddTaskDialog();
      },
    );
  }

  void _editTask(TodoTask task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTaskDialog(
          initialTask: task,
          isEditing: true,
        );
      },
    );
  }

  void _updateTaskStatus(TodoTask task, String newStatus) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final data = {
      'status': newStatus,
    };

    taskProvider.updateTask(task.uuid, data).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task updated to $newStatus'),
            backgroundColor: AppStyle.green,
          ),
        );
      }
    });
  }
}
