import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../../../core/di/injection.dart';
import '../../../../../../../components/custom_scaffold.dart';
import '../../../../../../../theme/theme.dart';
import '../providers/roadmap_provider.dart';
import '../providers/task_provider.dart';
import '../models/roadmap_version.dart';
import '../models/todo_task.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/add_roadmap_version_dialog.dart';

class AppRoadmapScreen extends StatefulWidget {
  final String? appId;
  final String? appName;

  const AppRoadmapScreen({
    super.key,
    this.appId,
    this.appName,
  });

  @override
  _AppRoadmapScreenState createState() => _AppRoadmapScreenState();
}

class _AppRoadmapScreenState extends State<AppRoadmapScreen> {
  String? _selectedVersionId;
  late RoadmapProvider _roadmapProvider;
  late TaskProvider _taskProvider;


  @override
  void initState() {
    super.initState();

    // Use the inject utility to get both providers
    _roadmapProvider = inject<RoadmapProvider>();
    _taskProvider = inject<TaskProvider>();

    // Use WidgetsBinding to ensure the context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch roadmap versions for the specific app
      _roadmapProvider.fetchRoadmapVersions(widget.appId);

      // Fetch tasks for the selected app
      _taskProvider.fetchTasks(null, appId: widget.appId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appName = widget.appName ?? 'App';

    return CustomScaffold(
      appBar: (colors) => AppBar(
        //title: Text('$appName Roadmap'),
        backgroundColor: colors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddVersionDialog,
            tooltip: 'Add Version',
          ),
        ],
      ),
      backgroundColor: AppStyle.white,
      body: (colors) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _roadmapProvider),
          ChangeNotifierProvider.value(value: _taskProvider),
        ],
        child: Consumer2<RoadmapProvider, TaskProvider>(
          builder: (context, roadmapProvider, taskProvider, child) {
            // Existing build method from the original implementation
            if (roadmapProvider.isLoading || taskProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (roadmapProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${roadmapProvider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          roadmapProvider.fetchRoadmapVersions(widget.appId),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (roadmapProvider.versions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No roadmap versions defined yet',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showAddVersionDialog,
                      child: const Text('Add Version'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _buildVersionSelector(roadmapProvider.versions),
                Expanded(
                  child: _selectedVersionId != null
                      ? _buildVersionContent(
                    _selectedVersionId!,
                    roadmapProvider,
                    taskProvider,
                  )
                      : const Center(
                    child: Text('Select a version to view details'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: (colors) => FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: AppStyle.accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVersionSelector(List<RoadmapVersion> versions) {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: versions.length,
        itemBuilder: (context, index) {
          final version = versions[index];
          final isSelected = version.id == _selectedVersionId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedVersionId = version.id;
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppStyle.primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppStyle.primary : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppStyle.primary.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'v${version.versionNumber}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    version.status,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVersionContent(
    String versionId,
    RoadmapProvider roadmapProvider,
    TaskProvider taskProvider,
  ) {
    final version =
        roadmapProvider.versions.firstWhere((v) => v.id == versionId);

    // Filter tasks for this version
    final versionTasks = taskProvider.tasks
        .where((task) =>
            task.roadmapVersion == version.versionNumber &&
            task.appId == widget.appId)
        .toList();

    // Group tasks by status
    final Map<String, List<TodoTask>> tasksByStatus = {
      'Todo': versionTasks.where((task) => task.status == 'Todo').toList(),
      'In Progress':
          versionTasks.where((task) => task.status == 'In Progress').toList(),
      'Done': versionTasks.where((task) => task.status == 'Done').toList(),
      'Blocked':
          versionTasks.where((task) => task.status == 'Blocked').toList(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Version ${version.versionNumber}',
                    style: AppStyle.heading2,
                  ),
                  Text(
                    'Status: ${version.status}',
                    style: TextStyle(
                      color: _getStatusColor(version.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (version.releaseDate != null)
                    Text(
                      'Target Release: ${version.releaseDate!.day}/${version.releaseDate!.month}/${version.releaseDate!.year}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editVersion(version),
                color: AppStyle.primary,
              ),
            ],
          ),
        ),
        if (version.description != null && version.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              version.description!,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildKanbanBoard(tasksByStatus),
        ),
      ],
    );
  }

  Widget _buildKanbanBoard(Map<String, List<TodoTask>> tasksByStatus) {
    return Row(
      children: [
        _buildKanbanColumn('Todo', tasksByStatus['Todo']!, Colors.grey),
        _buildKanbanColumn(
            'In Progress', tasksByStatus['In Progress']!, Colors.blue),
        _buildKanbanColumn('Done', tasksByStatus['Done']!, Colors.green),
        _buildKanbanColumn('Blocked', tasksByStatus['Blocked']!, Colors.red),
      ],
    );
  }

  Widget _buildKanbanColumn(String title, List<TodoTask> tasks, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: color.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tasks.length.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        return _buildTaskCard(tasks[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TodoTask task) {
    Color priorityColor;
    switch (task.priority) {
      case 'Urgent':
        priorityColor = Colors.red;
        break;
      case 'High':
        priorityColor = Colors.orange;
        break;
      case 'Medium':
        priorityColor = Colors.yellow.shade800;
        break;
      case 'Low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _editTask(task),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 20),
                  child: Text(
                    task.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (task.dueDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Planning':
        return Colors.blue;
      case 'Development':
        return Colors.orange;
      case 'Testing':
        return Colors.purple;
      case 'Released':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showAddVersionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddRoadmapVersionDialog(
          appId: widget.appId!,
        );
      },
    );
  }

  void _editVersion(RoadmapVersion version) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddRoadmapVersionDialog(
          appId: widget.appId!,
          initialVersion: version,
          isEditing: true,
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    if (_selectedVersionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a version first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final version = Provider.of<RoadmapProvider>(context, listen: false)
        .versions
        .firstWhere((v) => v.id == _selectedVersionId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTaskDialog(
          preSelectedAppId: widget.appId,
          // Change roadmapVersion to preSelectedRoadmapVersion
          preSelectedRoadmapVersion: version.versionNumber,
        );
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
}

