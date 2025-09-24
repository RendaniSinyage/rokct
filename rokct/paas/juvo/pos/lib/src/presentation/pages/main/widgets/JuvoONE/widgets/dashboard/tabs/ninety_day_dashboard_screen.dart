import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../../../core/di/injection.dart';
import '../../../../../../../../core/utils/utils.dart';
import '../../../../../../../components/custom_scaffold.dart';
import '../../../../../../../theme/theme.dart';
import '../providers/content_provider.dart';
import '../providers/plan_provider.dart';
import '../models/strategic_objective.dart';
import '../models/pillar.dart';
import '../widgets/add_objective_dialog.dart';
import 'kpi_dash.dart';

class NinetyDayDashboardScreen extends StatefulWidget {
  final String? shopId;

  const NinetyDayDashboardScreen({super.key, this.shopId});

  @override
  _NinetyDayDashboardScreenState createState() => _NinetyDayDashboardScreenState();
}

class _NinetyDayDashboardScreenState extends State<NinetyDayDashboardScreen> {
  late PlanProvider _planProvider;

  // Filtering variables
  String _selectedStatus = 'All Statuses';
  String _selectedPillar = 'All Pillars';

  @override
  void initState() {
    super.initState();

    // Use the inject utility to get the PlanProvider
    _planProvider = inject<PlanProvider>();

    // Fetch the plan when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _planProvider.fetchPlanOnPage(widget.shopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: (colors) => ChangeNotifierProvider.value(
        value: _planProvider,
        child: Consumer<PlanProvider>(
          builder: (context, planProvider, child) {
            if (planProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (planProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${planProvider.error}',
                      style: const TextStyle(color: AppStyle.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => planProvider.fetchPlanOnPage(widget.shopId),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (planProvider.vision == null) {
              return const Center(
                child: Text('No active vision found. Create one to get started.'),
              );
            }

            // Extract all priority objectives across pillars
            List<StrategicObjective> priorities = [];
            for (final pillar in planProvider.vision!.pillars) {
              for (final objective in pillar.strategicObjectives) {
                if (objective.is90DayPriority) {
                  priorities.add(objective);
                }
              }
            }

            final filteredPriorities = _filterPriorities(priorities, planProvider);

            if (filteredPriorities.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No 90-day priorities defined',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Set priorities from the Plan on a Page screen',
                      style: TextStyle(color: AppStyle.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Status Filter Chip
                      GestureDetector(
                        onTap: _showStatusFilterDialog,
                        child: Chip(
                          label: Text('Status: $_selectedStatus'),
                          backgroundColor: AppStyle.accentColor.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Pillar Filter Chip
                      GestureDetector(
                        onTap: _showPillarFilterDialog,
                        child: Chip(
                          label: Text('Pillar: $_selectedPillar'),
                          backgroundColor: AppStyle.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: filteredPriorities.length,
                    itemBuilder: (context, index) {
                      return _buildPriorityCard(
                        filteredPriorities[index],
                        planProvider,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: (colors) => FloatingActionButton(
        onPressed: _showAddObjectiveDialog,
        backgroundColor: AppStyle.accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper method to navigate to the Plan on a Page screen
  void _navigateToPlanOnPageScreen(BuildContext context) {
    // This should be replaced with the actual navigation logic in your app
    // For example, you might want to use the tab navigation system
    // or navigate to a new route depending on your app's architecture

    // Example using AutoRoute if available:
    // AutoRouter.of(context).push(PlanOnPageScreenRoute(shopId: widget.shopId));

    // Or using regular Navigator:
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlanOnPageScreen(shopId: widget.shopId),
      ),
    );
  }

  List<StrategicObjective> _filterPriorities(
      List<StrategicObjective> priorities,
      PlanProvider planProvider
      ) {
    return priorities.where((objective) {
      final statusMatch = _selectedStatus == 'All Statuses' ||
          objective.status == _selectedStatus;
      final pillarMatch = _selectedPillar == 'All Pillars' ||
          _getPillarName(objective, planProvider) == _selectedPillar;
      return statusMatch && pillarMatch;
    }).toList();
  }

  String _getPillarName(StrategicObjective objective, PlanProvider planProvider) {
    final pillar = planProvider.vision!.pillars
        .firstWhere((p) => p.id == objective.pillarId);
    return pillar.name;
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
              _buildStatusOption('Deferred'),
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

  void _showPillarFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter by Pillar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildPillarOptions(),
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

  List<Widget> _buildPillarOptions() {
    final pillarOptions = ['All Pillars'];

    // Add unique pillar names from the vision
    if (_planProvider.vision != null) {
      pillarOptions.addAll(
          _planProvider.vision!.pillars.map((pillar) => pillar.name).toSet()
      );
    }

    return pillarOptions.map((pillar) =>
        ListTile(
          title: Text(pillar),
          leading: Radio<String>(
            value: pillar,
            groupValue: _selectedPillar,
            onChanged: (String? value) {
              setState(() {
                _selectedPillar = value!;
              });
              Navigator.of(context).pop();
            },
          ),
          onTap: () {
            setState(() {
              _selectedPillar = pillar;
            });
            Navigator.of(context).pop();
          },
        )
    ).toList();
  }

  Widget _buildPriorityCard(
      StrategicObjective objective,
      PlanProvider planProvider
      ) {
    final pillar = planProvider.vision!.pillars
        .firstWhere((p) => p.id == objective.pillarId);

    Color pillarColor = _getPillarColor(pillar.color);

    // Calculate progress based on KPIs
    int totalKpis = objective.kpis.length;
    int completedKpis = objective.kpis.where((kpi) => kpi.status == 'Completed').length;
    double progress = totalKpis > 0 ? completedKpis / totalKpis : 0;

    // Determine if any KPIs are overdue
    bool hasOverdueKpis = objective.kpis.any((kpi) =>
    kpi.status != 'Completed' &&
        kpi.dueDate.isBefore(DateTime.now())
    );

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasOverdueKpis ? AppStyle.red : pillarColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _editObjective(objective, pillar),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: pillarColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getPillarIcon(pillar.icon),
                      color: pillarColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pillar.name,
                      style: TextStyle(
                        color: pillarColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasOverdueKpis ? AppStyle.red.withOpacity(0.1) : AppStyle.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: hasOverdueKpis ? AppStyle.red : AppStyle.accentColor,
                      ),
                    ),
                    child: Text(
                      '90-Day',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hasOverdueKpis ? AppStyle.red : AppStyle.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                objective.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (objective.description != null && objective.description!.isNotEmpty)
                Expanded(
                  child: Text(
                    objective.description!,
                    style: TextStyle(
                      color: AppStyle.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Spacer(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status: ${objective.status}',
                    style: TextStyle(
                      color: _getStatusColor(objective.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$completedKpis/$totalKpis KPIs',
                    style: TextStyle(
                      color: AppStyle.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppStyle.grey[200],
                color: hasOverdueKpis ? AppStyle.red : AppStyle.green,
              ),
              if (objective.targetDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: AppStyle.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${objective.targetDate!.day}/${objective.targetDate!.month}/${objective.targetDate!.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppStyle.grey[600],
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

  IconData _getPillarIcon(String? iconName) {
    if (iconName == null) {
      return Icons.star;
    }

    switch (iconName.toLowerCase()) {
      case 'people':
        return Icons.people;
      case 'process':
        return Icons.settings;
      case 'finance':
        return Icons.attach_money;
      case 'customers':
        return Icons.person;
      case 'social':
        return Icons.public;
      default:
        return Icons.star;
    }
  }

  Color _getPillarColor(String? colorString) {
    if (colorString == null) {
      return AppStyle.primary;
    }

    switch (colorString.toLowerCase()) {
      case 'purple':
        return AppStyle.peopleColor;
      case 'blue':
        return AppStyle.systemsColor;
      case 'green':
        return AppStyle.financeColor;
      case 'orange':
        return AppStyle.customersColor;
      case 'red':
        return AppStyle.socialColor;
      default:
        return AppStyle.primary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Not Started':
        return AppStyle.grey;
      case 'In Progress':
        return AppStyle.blue;
      case 'Completed':
        return AppStyle.green;
      case 'Deferred':
        return AppStyle.orange;
      default:
        return AppStyle.grey;
    }
  }

  void _showAddObjectiveDialog() {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    if (planProvider.vision == null || planProvider.vision!.pillars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create pillars first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Pillar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: planProvider.vision!.pillars.map((pillar) {
              return ListTile(
                title: Text(pillar.name),
                onTap: () {
                  Navigator.of(context).pop();
                  _openAddObjectiveDialog(pillar);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
            backgroundColor: AppStyle.white
        );
      },
    );
  }

  void _openAddObjectiveDialog(Pillar pillar) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddObjectiveDialog(
          pillar: pillar,
          isEditing: false,
        );
      },
    );
  }

  void _editObjective(StrategicObjective objective, Pillar pillar) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddObjectiveDialog(
          pillar: pillar,
          initialObjective: objective,
          isEditing: true,
        );
      },
    );
  }
}
