import 'package:intl/intl.dart';

final List<Map<String, dynamic>> dummyData = [
  {
    'shopId': 9003,
    'tanks': [
      {
        'number': 1,
        'type': 'raw',
        'capacity': 4900,
        'lastUpdated': DateTime.now().toIso8601String(),
        'lastFull': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'waterQuality': {'ph': 7.3, 'tds': 175, 'temperature': 16, 'hardness': 23},
        'pumpStatus': {'isOn': true, 'flowRate': 5.8}
      },
      {
        'number': 2,
        'type': 'purified',
        'capacity': 4900,
        'lastUpdated': DateTime.now().toIso8601String(),
       // 'lastFull': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'lastFull': '2024-10-11T10:00:00Z',
        'waterQuality': {'ph': 6.9, 'tds': 14, 'temperature': 16, 'hardness': 4},
        'pumpStatus': {'isOn': false, 'flowRate': 5.2}
      },
      {
        'number': 3,
        'type': 'raw',
        'capacity': 2000,
        'lastUpdated': DateTime.now().toIso8601String(),
        'lastFull': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
        'waterQuality': {'ph': 7.1, 'tds': 170, 'temperature': 16, 'hardness': 24},
        'pumpStatus': {'isOn': false, 'flowRate': 0}
      }
    ],
    'roSystem': {
      'status': 'Running',
      'lastMaintenance': '2024-08-15',
      'membranes': [
        {'lastReplaced': '2024-09-14'},
        {'lastReplaced': '2024-09-14'}
      ],
      'megaCharVessels': [
        {'lastReplaced': '2024-09-14'}
      ]
    },
    'maintenance': {
      'lastBackwash': '2024-09-18',
      'mediaLastReplaced': '2024-09-14',
      'softenerLastReplaced': '2024-09-14',
      'preFilterLastReplaced': '2024-07-15',
      'postFilterLastReplaced': '2024-05-15',
      'periods': {
        'backwash': 7,
        'membrane': 365,
        'mediaReplacement': 365,
        'preFilter': 90,
        'postFilter': 180
      }
    },
    'energyPurchases': [
      {'date': '2024-09-01', 'kwh': 110, 'cost': 165},
      {'date': '2024-09-08', 'kwh': 145, 'cost': 217.5},
      {'date': '2024-09-15', 'kwh': 125, 'cost': 187.5}
    ]
  },
  {
    'shopId': 9001,
    'tanks': [
      {
        'number': 1,
        'type': 'raw',
        'capacity': 4900,
        'lastUpdated': DateTime.now().toIso8601String(),
        'lastFull': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'waterQuality': {'ph': 7.4, 'tds': 178, 'temperature': 17, 'hardness': 28},
        'pumpStatus': {'isOn': true, 'flowRate': 6.1}
      },
      {
        'number': 2,
        'type': 'purified',
        'capacity': 4900,
        'lastUpdated': DateTime.now().toIso8601String(),
        'lastFull': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'waterQuality': {'ph': 6.7, 'tds': 13, 'temperature': 17, 'hardness': 3},
        'pumpStatus': {'isOn': false, 'flowRate': 5.3}
      },
      {
        'number': 3,
        'type': 'raw',
        'capacity': 2000,
        'lastUpdated': DateTime.now().toIso8601String(),
        'lastFull': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'waterQuality': {'ph': 7.2, 'tds': 176, 'temperature': 17, 'hardness': 29},
        'pumpStatus': {'isOn': false, 'flowRate': 0}
      }
    ],
    'roSystem': {
      'status': 'Running',
      'lastMaintenance': '2024-08-30',
      'membranes': [
        {'lastReplaced': '2024-10-01'},
        {'lastReplaced': '2024-10-01'},
        {'lastReplaced': '2024-10-01'},
        {'lastReplaced': '2024-10-01'}
      ],
      'megaCharVessels': [
        {'lastReplaced': '2024-10-01'},
        {'lastReplaced': '2024-10-01'}
      ]
    },
    'maintenance': {
      'lastBackwash': '2024-09-20',
      'mediaLastReplaced': '2024-10-01',
      'softenerLastReplaced': '2024-10-01',
      'preFilterLastReplaced': '2024-08-01',
      'postFilterLastReplaced': '2024-06-01',
      'periods': {
        'backwash': 7,
        'membrane': 365,
        'mediaReplacement': 365,
        'preFilter': 90,
        'postFilter': 180
      }
    },
    'energyPurchases': [
      {'date': '2024-09-01', 'kwh': 118, 'cost': 177},
      {'date': '2024-09-07', 'kwh': 135, 'cost': 202.5},
      {'date': '2024-09-14', 'kwh': 150, 'cost': 225}
    ]
  }
];
