import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../../../core/di/injection.dart';
import '../../../../../../../../core/utils/utils.dart';
import '../../../../../../../components/custom_scaffold.dart';
import '../../../../../../../theme/theme.dart';
import '../widgets/add_vision_dialog.dart';
import '../providers/plan_provider.dart';
import '../models/vision.dart';
import '../models/pillar.dart';
import '../models/strategic_objective.dart';
import '../models/kpi.dart';
import '../widgets/add_pillar_dialog.dart';
import '../widgets/add_objective_dialog.dart';
import '../widgets/add_kpi_dialog.dart';

// Custom ArrowBox widget to create the arrow-shaped containers
enum ArrowDirection { left, right }

class ArrowBox extends StatelessWidget {
  final Color color;
  final Widget child;
  final ArrowDirection direction;
  final double arrowWidth;
  final double arrowHeight;

  const ArrowBox({
    Key? key,
    required this.color,
    required this.child,
    this.direction = ArrowDirection.right,
    this.arrowWidth = 20.0,
    this.arrowHeight = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ArrowPainter(
        color: color,
        direction: direction,
        arrowWidth: arrowWidth,
        arrowHeight: arrowHeight,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: direction == ArrowDirection.right ? 12.0 : arrowWidth + 12.0,
          right: direction == ArrowDirection.left ? 12.0 : arrowWidth + 12.0,
          top: 12.0,
          bottom: 12.0,
        ),
        child: child,
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  final Color color;
  final ArrowDirection direction;
  final double arrowWidth;
  final double arrowHeight;

  ArrowPainter({
    required this.color,
    required this.direction,
    required this.arrowWidth,
    required this.arrowHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();

    if (direction == ArrowDirection.right) {
      // Start from top-left
      path.moveTo(0, 0);
      // Draw line to right side before arrow
      path.lineTo(size.width - arrowWidth, 0);
      // Draw diagonal line to arrow tip
      path.lineTo(size.width, size.height / 2);
      // Draw diagonal line back from arrow tip
      path.lineTo(size.width - arrowWidth, size.height);
      // Draw line to bottom-left
      path.lineTo(0, size.height);
      // Close the path
      path.close();
    } else {
      // Start from top-right
      path.moveTo(size.width, 0);
      // Draw line to left side before arrow
      path.lineTo(arrowWidth, 0);
      // Draw diagonal line to arrow tip
      path.lineTo(0, size.height / 2);
      // Draw diagonal line back from arrow tip
      path.lineTo(arrowWidth, size.height);
      // Draw line to bottom-right
      path.lineTo(size.width, size.height);
      // Close the path
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PlanOnPageScreen extends StatefulWidget {
  final String? shopId;

  const PlanOnPageScreen({super.key, this.shopId});

  @override
  _PlanOnPageScreenState createState() => _PlanOnPageScreenState();
}

class _PlanOnPageScreenState extends State<PlanOnPageScreen> {
  late PlanProvider _planProvider;
  bool _showVisionOverlay = true;

  @override
  void initState() {
    super.initState();

    // Determine shop ID
    final effectiveShopId =
        widget.shopId ?? LocalStorage.getUser()?.shop?.id?.toString();

    if (kDebugMode) {
      print('Initializing PlanOnPageScreen');
      print('Passed Shop ID: ${widget.shopId}');
      print('User Shop ID: ${LocalStorage.getUser()?.shop?.id}');
      print('Effective Shop ID: $effectiveShopId');
    }

    // Use the inject utility to get the PlanProvider
    _planProvider = inject<PlanProvider>();

    // Use WidgetsBinding to ensure the context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _planProvider.fetchPlanOnPage(widget.shopId);
    });
  }

  // Helper to group pillars by icon (category type)
  Map<String, List<Pillar>> _groupPillarsByName(List<Pillar> pillars) {
    Map<String, List<Pillar>> groupedPillars = {};

    for (var pillar in pillars) {
      // Use the icon as the category key, or a fallback if not available
      String categoryKey = (pillar.icon ?? "undefined").toLowerCase();

      if (!groupedPillars.containsKey(categoryKey)) {
        groupedPillars[categoryKey] = [];
      }
      groupedPillars[categoryKey]!.add(pillar);
    }

    return groupedPillars;
  }

  // Helper to show a selection dialog when multiple pillars of same type exist
  void _showPillarSelectionForEdit(BuildContext context, List<Pillar> pillars) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select ${pillars.first.name} Pillar to Edit',
              style: TextStyle(color: AppStyle.black)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: pillars.map((pillar) {
                return ListTile(
                  title: Text(pillar.description ?? pillar.name,
                      style: TextStyle(color: AppStyle.black)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _editPillar(pillar);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
          backgroundColor: AppStyle.white,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: AppStyle.white,
      body: (colors) => ChangeNotifierProvider<PlanProvider>.value(
        value: _planProvider,
        child: Consumer<PlanProvider>(
          builder: (context, planProvider, _) {
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
                      onPressed: () =>
                          planProvider.fetchPlanOnPage(widget.shopId),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (planProvider.vision == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No active vision found. Create one to get started.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showAddVisionDialog(context),
                      child: const Text('Create Vision'),
                    ),
                  ],
                ),
              );
            }

            // Show arrow-based layout with the vision overlay if needed
            return Stack(
              children: [
                // Main content
                _buildArrowPlanOnPage(planProvider.vision!),

                // Vision overlay (only if showVisionOverlay is true)
                if (_showVisionOverlay && planProvider.vision != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showVisionOverlay = false;
                      });
                    },
                    onDoubleTap: () {
                      _editVision(planProvider.vision!);
                    },
                    child: _buildVisionOverlay(planProvider.vision!),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: (colors) => FloatingActionButton(
        onPressed: () => _showAddOptionsDialog(context),
        backgroundColor: AppStyle.accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVisionOverlay(Vision vision) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppStyle.white,
            AppStyle.white,
            AppStyle.white.withOpacity(0.9),
            AppStyle.white.withOpacity(0.8),
            AppStyle.white.withOpacity(0.4),
          ],
          stops: const [0.0, 0.4, 0.6, 0.7, 1.0],
          transform: GradientRotation(math.pi / 4), // Slight vertical gradient
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VISION',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: AppStyle.black,
              ),
            ),
            const SizedBox(height: 24),
            RichText(
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              text: _formatVisionTextRich(vision.statement),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildArrowPlanOnPage(Vision vision) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            width: constraints.maxWidth,
            child: IntrinsicHeight( // 🛠 wrap this correctly as `child`
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KPIs Column (Left)
                  Expanded(
                    flex: 5,
                    child: _buildKPIsColumn(vision.pillars),
                  ),

                  // Strategic Objectives Column (Middle-Left)
                  Expanded(
                    flex: 5,
                    child: _buildStrategicObjectivesColumn(vision.pillars),
                  ),

                  // Five Pillars Column (Right)
                  Expanded(
                    flex: 4,
                    child: _buildFivePillarsColumn(vision.pillars),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKPIsColumn(List<Pillar> pillars) {
    // Group pillars by name to combine identical categories
    Map<String, List<Pillar>> groupedPillars = _groupPillarsByName(pillars);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppStyle.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: const Text(
            'KEY PERFORMANCE INDICATORS (KPI\'s)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppStyle.black,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // KPIs by pillar group
        ...groupedPillars.entries.map((entry) {
          String pillarName = entry.key;
          List<Pillar> pillarsInGroup = entry.value;

          // Use the color from the first pillar in the group
          Color pillarColor = _getPillarColor(pillarsInGroup.first.color);

          // Collect all KPIs from all pillars in this group
          List<Kpi> pillarKpis = [];
          for (var pillar in pillarsInGroup) {
            for (var objective in pillar.strategicObjectives) {
              pillarKpis.addAll(objective.kpis);
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ArrowBox(
              color: pillarColor,
              direction: ArrowDirection.right,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: pillarKpis.isEmpty
                    ? [
                        Text(
                          'No KPIs defined',
                          style: TextStyle(
                            color: AppStyle.black,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      ]
                    : pillarKpis.map((kpi) {
                        bool isOverdue = kpi.status != 'Completed' &&
                            kpi.dueDate.isBefore(DateTime.now());

                        return GestureDetector(
                          onDoubleTap: () => _editKpi(kpi),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: AppStyle.black,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "${kpi.metric} (${_formatDueDate(kpi.dueDate)})",
                                    style: TextStyle(
                                      color: AppStyle.black,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStrategicObjectivesColumn(List<Pillar> pillars) {
    // Group pillars by name to combine identical categories
    Map<String, List<Pillar>> groupedPillars = _groupPillarsByName(pillars);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppStyle.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: const Text(
            'STRATEGIC OBJECTIVES',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppStyle.black,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Strategic Objectives by pillar group
        ...groupedPillars.entries.map((entry) {
          String pillarName = entry.key;
          List<Pillar> pillarsInGroup = entry.value;

          // Use the color from the first pillar in the group
          Color pillarColor = _getPillarColor(pillarsInGroup.first.color);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ArrowBox(
              color: pillarColor,
              direction: ArrowDirection.right,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pillar-specific heading
                  Text(
                    pillarName.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppStyle.black,
                    ),
                  ),

                  // If multiple pillars in group, show count
                  if (pillarsInGroup.length > 1)
                    Text(
                      '(${pillarsInGroup.length} pillars)',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: AppStyle.black,
                      ),
                    ),

                  // Otherwise, show description of the single pillar
                  if (pillarsInGroup.length == 1)
                    Text(
                      pillarsInGroup.first.description ?? "",
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: AppStyle.black,
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Collect and display all objectives from all pillars in this group
                  _buildObjectivesListForPillarGroup(pillarsInGroup),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildObjectivesListForPillarGroup(List<Pillar> pillarsInGroup) {
    // Collect all objectives from all pillars in this group
    List<StrategicObjective> allObjectives = [];
    for (var pillar in pillarsInGroup) {
      allObjectives.addAll(pillar.strategicObjectives);
    }

    if (allObjectives.isEmpty) {
      return Text(
        'No objectives defined',
        style: TextStyle(
          color: AppStyle.black,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allObjectives.asMap().entries.map((entry) {
        int index = entry.key + 1;
        StrategicObjective objective = entry.value;
        return GestureDetector(
          onDoubleTap: () => _editObjective(objective),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$index. ",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppStyle.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    objective.title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppStyle.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFivePillarsColumn(List<Pillar> pillars) {
    // Group pillars by name to combine identical categories
    Map<String, List<Pillar>> groupedPillars = _groupPillarsByName(pillars);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppStyle.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: const Text(
            'FIVE PILLARS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppStyle.black,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Pillars grouped by category
        ...groupedPillars.entries.map((entry) {
          String pillarName = entry.key;
          List<Pillar> pillarsInGroup = entry.value;

          // Use the color from the first pillar in the group
          Color pillarColor = _getPillarColor(pillarsInGroup.first.color);

          // Use the icon from the first pillar with an icon, or default
          IconData iconData = Icons.star;
          for (var pillar in pillarsInGroup) {
            if (pillar.icon != null) {
              iconData = _getIconData(pillar.icon!);
              break;
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ArrowBox(
              color: pillarColor,
              direction: ArrowDirection.right,
              child: GestureDetector(
                onDoubleTap: () {
                  // If there's only one pillar in the group, edit it directly
                  if (pillarsInGroup.length == 1) {
                    _editPillar(pillarsInGroup.first);
                  } else {
                    // Otherwise, show a selection dialog
                    _showPillarSelectionForEdit(context, pillarsInGroup);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      iconData,
                      color: AppStyle.black,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pillarName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppStyle.black,
                      ),
                    ),
                    // If multiple pillars, show count
                    if (pillarsInGroup.length > 1)
                      Text(
                        '(${pillarsInGroup.length} pillars)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppStyle.black,
                        ),
                      )
                    // Otherwise show description
                    else
                      Text(
                        pillarsInGroup.first.description ?? "",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppStyle.black,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),

        // Vision Button
        if (!_showVisionOverlay)
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showVisionOverlay = true;
              });
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Show Vision'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.primary,
            ),
          ),
      ],
    );
  }

  String _formatDueDate(DateTime date) {
    // Get month abbreviation
    String month;
    switch (date.month) {
      case 1:
        month = 'Jan';
        break;
      case 2:
        month = 'Feb';
        break;
      case 3:
        month = 'Mar';
        break;
      case 4:
        month = 'Apr';
        break;
      case 5:
        month = 'May';
        break;
      case 6:
        month = 'Jun';
        break;
      case 7:
        month = 'Jul';
        break;
      case 8:
        month = 'Aug';
        break;
      case 9:
        month = 'Sep';
        break;
      case 10:
        month = 'Oct';
        break;
      case 11:
        month = 'Nov';
        break;
      case 12:
        month = 'Dec';
        break;
      default:
        month = '';
        break;
    }

    return month;
  }

  // Helper method to format the vision text into lines with max 4 words per line
  TextSpan _formatVisionTextRich(String visionText) {
    String uppercaseText = visionText.toUpperCase();
    List<String> words = uppercaseText.split(' ');

    List<String> lines = [];
    int i = 0;

    // First line: just 1 word
    if (words.isNotEmpty) {
      lines.add(words[i]);
      i++;
    }

    // Grouping logic with comma break
    while (i < words.length) {
      List<String> lineWords = [];
      while (i < words.length && lineWords.length < 3) {
        String word = words[i];
        lineWords.add(word);
        i++;
        if (word.endsWith(',')) break;
      }
      lines.add(lineWords.join(' '));
    }

    // Build spans
    List<InlineSpan> spans = [];
    final style = AppStyle.logoFontBoldItalic(size: 50);
    for (int j = 0; j < lines.length; j++) {
      List<String> lineWords = lines[j].split(' ');
      for (int k = 0; k < lineWords.length; k++) {
        String word = lineWords[k];
        bool isLastWord = (j == lines.length - 1) && (k == lineWords.length - 1);

        if (isLastWord) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppStyle.primary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                word,
                style: style.copyWith(color: Colors.white),
              ),
            ),
          ));
        } else {
          spans.add(TextSpan(text: '$word ', style: style));
          if (k < lineWords.length - 1) {
            spans.add(const TextSpan(text: ' '));
          }
        }
      }
      if (j < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans);
  }



  // Helper methods
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

  IconData _getIconData(String iconName) {
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

  // Dialog methods
  void _showAddOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add to Plan',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppStyle.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility, color: AppStyle.black),
                title: const Text('Vision',
                    style: TextStyle(color: AppStyle.black)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddVisionDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.view_column, color: AppStyle.black),
                title: const Text('Pillar',
                    style: TextStyle(color: AppStyle.black)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddPillarDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment, color: AppStyle.black),
                title: const Text('Strategic Objective',
                    style: TextStyle(color: AppStyle.black)),
                onTap: () {
                  Navigator.of(context).pop();
                  // Show pillar selection dialog first
                  _selectPillarForObjective(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.assessment, color: AppStyle.black),
                title:
                    const Text('KPI', style: TextStyle(color: AppStyle.black)),
                onTap: () {
                  Navigator.of(context).pop();
                  // Show objective selection dialog first
                  _selectObjectiveForKpi(context, null);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
          backgroundColor: AppStyle.white,
        );
      },
    );
  }

  void _showAddVisionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddVisionDialog();
      },
    ).then((_) {
      // After dialog is closed, make sure vision overlay is shown
      setState(() {
        _showVisionOverlay = true;
      });
    });
  }

  void _showAddPillarDialog(BuildContext context) {
    if (_planProvider.vision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a vision first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddPillarDialog(visionId: _planProvider.vision!.id);
      },
    );
  }

  void _selectPillarForObjective(BuildContext context) {
    if (_planProvider.vision == null || _planProvider.vision!.pillars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create pillars first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Pillar',
              style: TextStyle(color: AppStyle.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _planProvider.vision!.pillars.map((pillar) {
              return ListTile(
                title: Text(pillar.name,
                    style: const TextStyle(color: AppStyle.black)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddObjectiveDialog(context, pillar);
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
          backgroundColor: AppStyle.white,
        );
      },
    );
  }

  void _showAddObjectiveDialog(BuildContext context, Pillar pillar) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddObjectiveDialog(pillar: pillar);
      },
    );
  }

  void _selectObjectiveForKpi(BuildContext context, Pillar? specificPillar) {
    if (_planProvider.vision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a vision first')),
      );
      return;
    }

    // Get all objectives, or just the objectives for a specific pillar if provided
    List<StrategicObjective> availableObjectives = [];
    if (specificPillar != null) {
      availableObjectives.addAll(specificPillar.strategicObjectives);
    } else {
      for (var pillar in _planProvider.vision!.pillars) {
        availableObjectives.addAll(pillar.strategicObjectives);
      }
    }

    if (availableObjectives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please create strategic objectives first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Strategic Objective',
              style: TextStyle(color: AppStyle.black)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableObjectives.map((objective) {
                final pillar = _planProvider.vision!.pillars
                    .firstWhere((p) => p.id == objective.pillarId);
                return ListTile(
                  title: Text(objective.title,
                      style: const TextStyle(color: AppStyle.black)),
                  subtitle: Text(pillar.name),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAddKpiDialog(context, objective);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
          backgroundColor: AppStyle.white,
        );
      },
    );
  }

  void _showAddKpiDialog(BuildContext context, StrategicObjective objective) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddKpiDialog(objective: objective);
      },
    );
  }

  void _editVision(Vision vision) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddVisionDialog(
          initialVision: vision,
          isEditing: true,
        );
      },
    ).then((_) {
      // After dialog is closed, make sure vision overlay is shown
      setState(() {
        _showVisionOverlay = true;
      });
    });
  }

  void _editPillar(Pillar pillar) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddPillarDialog(
          visionId: pillar.visionId,
          initialPillar: pillar,
          isEditing: true,
        );
      },
    );
  }

  void _editObjective(StrategicObjective objective) {
    Pillar pillar = _planProvider.vision!.pillars
        .firstWhere((p) => p.id == objective.pillarId);

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

  void _editKpi(Kpi kpi) {
    // Find the objective this KPI belongs to
    StrategicObjective? objective;
    for (var pillar in _planProvider.vision!.pillars) {
      for (var obj in pillar.strategicObjectives) {
        if (obj.id == kpi.objectiveId) {
          objective = obj;
          break;
        }
      }
      if (objective != null) break;
    }

    if (objective == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not find the associated objective')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddKpiDialog(
          objective: objective!,
          initialKpi: kpi,
          isEditing: true,
        );
      },
    );
  }
}

