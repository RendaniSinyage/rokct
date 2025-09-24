import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../../../core/di/injection.dart';
import '../../../../../../../components/custom_scaffold.dart';
import '../../../../../../../theme/theme.dart';
import '../providers/personal_mastery_provider.dart';
import '../models/personal_mastery_goal.dart';
import '../widgets/add_personal_goal_dialog.dart';

class PersonalMasteryScreen extends StatefulWidget {
  final String? userId;

  const PersonalMasteryScreen({Key? key, this.userId}) : super(key: key);

  @override
  _PersonalMasteryScreenState createState() => _PersonalMasteryScreenState();
}

class _PersonalMasteryScreenState extends State<PersonalMasteryScreen> {
  late PersonalMasteryProvider _personalMasteryProvider;
  String _selectedArea = 'All Areas';
  String _selectedStatus = 'All Statuses';

  @override
  void initState() {
    super.initState();

    // Use the inject utility to get the PersonalMasteryProvider
    _personalMasteryProvider = inject<PersonalMasteryProvider>();

    // Fetch personal mastery goals when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _personalMasteryProvider.fetchPersonalMasteryGoals(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: (colors) => ChangeNotifierProvider.value(
        value: _personalMasteryProvider,
        child: Consumer<PersonalMasteryProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${provider.error}',
                      style: const TextStyle(color: AppStyle.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.fetchPersonalMasteryGoals(null),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final filteredGoals = _filterGoals(provider.goals);

            if (filteredGoals.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No personal goals found',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showAddGoalDialog(),
                      child: const Text('Create Goal'),
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
                      _buildFilterChip(
                        label: 'Area: $_selectedArea',
                        onTap: _showAreaFilterDialog,
                        onDeleted: () => setState(() { _selectedArea = 'All Areas'; }),
                        isDeletable: _selectedArea != 'All Areas',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Status: $_selectedStatus',
                        onTap: _showStatusFilterDialog,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredGoals.length,
                    itemBuilder: (context, index) {
                      return _buildGoalCard(filteredGoals[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: (colors) => FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: AppStyle.accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<PersonalMasteryGoal> _filterGoals(List<PersonalMasteryGoal> goals) {
    return goals.where((goal) {
      final areaMatch = _selectedArea == 'All Areas' || goal.area == _selectedArea;
      final statusMatch = _selectedStatus == 'All Statuses' || goal.status == _selectedStatus;
      return areaMatch && statusMatch;
    }).toList();
  }

  void _showAreaFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter by Area'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAreaOption('All Areas'),
              _buildAreaOption('Financial'),
              _buildAreaOption('Vocation/Work'),
              _buildAreaOption('Family'),
              _buildAreaOption('Friends'),
              _buildAreaOption('Spiritual'),
              _buildAreaOption('Physical'),
              _buildAreaOption('Learning & Skills'),
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

  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter by Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption('All Statuses'),
              _buildStatusOption('Not Started'),
              _buildStatusOption('In Progress'),
              _buildStatusOption('Completed'),
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

  Widget _buildAreaOption(String area) {
    return ListTile(
      title: Text(area),
      leading: Radio<String>(
        value: area,
        groupValue: _selectedArea,
        onChanged: (String? value) {
          setState(() {
            _selectedArea = value!;
          });
          Navigator.of(context).pop();
        },
      ),
      onTap: () {
        setState(() {
          _selectedArea = area;
        });
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildStatusOption(String status) {
    return ListTile(
      title: Text(status),
      leading: Radio<String>(
        value: status,
        groupValue: _selectedStatus,
        onChanged: (String? value) {
          setState(() {
            _selectedStatus = value!;
          });
          Navigator.of(context).pop();
        },
      ),
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildGoalCard(PersonalMasteryGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _editGoal(goal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(goal.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      goal.status,
                      style: TextStyle(
                        color: _getStatusColor(goal.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                goal.area,
                style: TextStyle(
                  color: AppStyle.grey[600],
                ),
              ),
              if (goal.description != null && goal.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  goal.description!,
                  style: TextStyle(
                    color: AppStyle.grey[700],
                  ),
                ),
              ],
              if (goal.targetDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppStyle.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Target: ${goal.targetDate!.day}/${goal.targetDate!.month}/${goal.targetDate!.year}',
                      style: TextStyle(
                        color: AppStyle.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Not Started':
        return AppStyle.grey;
      case 'In Progress':
        return AppStyle.blue;
      case 'Completed':
        return AppStyle.green;
      default:
        return AppStyle.grey;
    }
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddPersonalGoalDialog();
      },
    );
  }

  void _editGoal(PersonalMasteryGoal goal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddPersonalGoalDialog(
          initialGoal: goal,
          isEditing: true,
        );
      },
    );
  }
}

Widget _buildFilterChip({
  required String label,
  VoidCallback? onTap,
  VoidCallback? onDeleted,
  bool isDeletable = false,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Chip(
      label: Text(label),
      deleteIcon: isDeletable ? const Icon(Icons.clear) : null,
      onDeleted: isDeletable ? onDeleted : null,
    ),
  );
}
