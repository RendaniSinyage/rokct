import 'package:flutter/material.dart';

import 'dashboard_entry.dart';
import 'tabs/kpi_dash.dart';
import 'tabs/todo_list.dart';
import 'tabs/goals_dash.dart';
import 'tabs/personal_mastery_screen.dart';
import 'tabs/ninety_day_dashboard_screen.dart';
import 'tabs/roadmap_dash.dart';

export 'dashboard_entry.dart';
export 'tabs/kpi_dash.dart';
export 'tabs/personal_mastery_screen.dart';
export 'tabs/todo_list.dart';
export 'tabs/goals_dash.dart';
export 'tabs/ninety_day_dashboard_screen.dart';
export 'tabs/roadmap_dash.dart';

const List<String> dashboardTabTitles = [
  'Dashboard',
  'Plans',
  'Todo',
  //'Goals',
  'Mastery',
  '90Days',
  'RoadMap',


  //'Income Page'
];
final List<Widget> dashboardTabWidgets = [
  const DashboardEntry(),
  const PlanOnPageScreen(),
  const TodoTasksScreen(),
 // const GoalsScreen(),
  const PersonalMasteryScreen(),
  const NinetyDayDashboardScreen(),
  const AppRoadmapScreen(),
];




