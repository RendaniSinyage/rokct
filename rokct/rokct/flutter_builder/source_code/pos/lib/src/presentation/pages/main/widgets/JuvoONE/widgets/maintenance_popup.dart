import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MaintenanceProcedure extends StatelessWidget {
  final String vessel;
  final VoidCallback onComplete;

  const MaintenanceProcedure({super.key, required this.vessel, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${vessel == 'megaChar' ? 'Mega Char' : 'Softener'} Maintenance',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[500],  // Replaces 'primary'
              foregroundColor: Colors.white,      // Replaces 'onPrimary'
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Complete Maintenance'),
          ),
        ],
      ),
    );
  }
}

class MaintenanceAlert {
  final String type;
  final String message;

  MaintenanceAlert({required this.type, required this.message});
}

class MaintenancePopup extends StatefulWidget {
  final List<MaintenanceAlert> initialAlerts;
  final VoidCallback onClose;

  const MaintenancePopup({super.key, required this.initialAlerts, required this.onClose});

  @override
  _MaintenancePopupState createState() => _MaintenancePopupState();
}

class _MaintenancePopupState extends State<MaintenancePopup> {
  String? activeMaintenance;

  void handleMaintenanceAction(MaintenanceAlert alert, String action) {
    if (action == 'confirm') {
      setState(() {
        activeMaintenance = alert.type;
      });
    }
  }

  void handleMaintenanceComplete() {
    setState(() {
      activeMaintenance = null;
    });
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    if (activeMaintenance != null) {
      return MaintenanceProcedure(
        vessel: activeMaintenance!,
        onComplete: handleMaintenanceComplete,
      );
    }

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Maintenance Alerts',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const SizedBox(height: 16),
            widget.initialAlerts.isNotEmpty
                ? ListView.separated(
              shrinkWrap: true,
              itemCount: widget.initialAlerts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final alert = widget.initialAlerts[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/alert-triangle.svg',
                          width: 18,
                          height: 18,
                          color: Colors.yellow[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(alert.message)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => handleMaintenanceAction(alert, 'confirm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[500],  // Replaces 'primary'
                          foregroundColor: Colors.white,      // Replaces 'onPrimary'
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                );
              },
            )
                : Text(
              'No maintenance alerts at this time.',
              style: TextStyle(color: Colors.green[600]),
            ),
          ],
        ),
      ),
    );
  }
}
