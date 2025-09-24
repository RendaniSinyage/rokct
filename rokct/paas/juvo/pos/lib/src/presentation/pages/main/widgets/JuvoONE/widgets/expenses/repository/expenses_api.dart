import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../../core/utils/utils.dart';
import '../expenses_statistics.dart';
import '../../roSystem/models/data/expense_data.dart';
import '../expenses_type.dart';


class ExpenseService {
  static const String baseUrl = '${AppConstants.baseUrl}api/v1/rest/resources';

  static Future<Map<String, String>> _getHeaders() async {
    final token = await LocalStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Future<int?> _getShopId() async {
    final userData = await LocalStorage.getUser();
    if (userData?.shop?.id == null) {
      throw Exception('Shop data not found');
    }
    return userData?.shop?.id;
  }

  // GET /expenses
  Future<List<Expense>> getExpenses({
    int? shopId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 15,
  }) async {
    final actualShopId = shopId ?? await _getShopId();

    final queryParams = {
      'shop_id': actualShopId.toString(),
      if (startDate != null) 'date_from': DateFormat('yyyy-MM-dd').format(startDate),
      if (endDate != null) 'date_to': DateFormat('yyyy-MM-dd').format(endDate),
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    final uri = Uri.parse('$baseUrl/expenses').replace(queryParameters: queryParams);
    if (kDebugMode) {
      print('⭐️ Expenses Request URI: $uri');
    } // Debug the request URL

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);
      if (kDebugMode) {
        print('⭐️ Expenses Response: ${response.body}');
      } // Debug the response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final paginatedData = data['data'] as Map<String, dynamic>;
          final expensesData = paginatedData['data'] as List;
          if (kDebugMode) {
            print('⭐️ Got ${expensesData.length} expenses from API');
          }
          return expensesData.map((json) => Expense.fromJson(json)).toList();
        }
        throw Exception(data['message'] ?? 'Failed to load expenses');
      }
      throw Exception('Failed to load expenses. Status: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('⭐️ Error in getExpenses: $e');
      } // Debug any errors
      throw Exception('Error fetching expenses: ${e.toString()}');
    }
  }

  // GET /expenses/types
  Future<List<ExpenseType>> getExpenseTypes() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/expenses-types');

      if (kDebugMode) {
        print('⭐️ Requesting Expense Types from: $uri');
      }
      if (kDebugMode) {
        print('⭐️ Headers: $headers');
      }

      final response = await http.get(
        uri,
        headers: headers,
      );

      if (kDebugMode) {
        print('⭐️ Response Status Code: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('⭐️ Response Headers: ${response.headers}');
      }
      if (kDebugMode) {
        print('⭐️ Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('⭐️ Decoded Data: $data');
        }

        if (data['success']) {
          if (data['data'] == null) {
            if (kDebugMode) {
              print('⭐️ Warning: data field is null');
            }
            return [];
          }

          if (data['data'] is! List) {
            if (kDebugMode) {
              print('⭐️ Warning: data field is not a List (${data['data'].runtimeType})');
            }
            return [];
          }

          final types = (data['data'] as List)
              .map((json) {
            if (kDebugMode) {
              print('⭐️ Processing type: $json');
            }
            return ExpenseType.fromJson(json);
          })
              .toList();

          if (kDebugMode) {
            print('⭐️ Successfully parsed ${types.length} expense types');
          }
          return types;
        }

        print('⭐️ API returned success: false');
        throw Exception(data['message'] ?? 'Failed to load expense types');
      }

      print('⭐️ Non-200 status code received');
      throw Exception('Failed to load expense types. Status: ${response.statusCode}. Body: ${response.body}');
    } catch (e, stackTrace) {
      print('⭐️ Error in getExpenseTypes: $e');
      print('⭐️ Stack Trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<ExpenseTypeStats>> getExpenseTypeStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = {
        if (startDate != null) 'date_from': DateFormat('yyyy-MM-dd').format(startDate),
        if (endDate != null) 'date_to': DateFormat('yyyy-MM-dd').format(endDate),
      };

      final uri = Uri.parse('$baseUrl/expenses/type-statistics').replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      print('⭐️ Expense Type Stats Response Status: ${response.statusCode}');
      if (kDebugMode) {
        print('⭐️ Expense Type Stats Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('⭐️ Decoded Expense Type Stats Data: $data');
        }

        if (data['success'] == true) {
          // Ensure 'data' is a List before mapping
          if (data['data'] is List) {
            final stats = (data['data'] as List)
                .map((dynamic json) =>
            json is Map<String, dynamic>
                ? ExpenseTypeStats.fromJson(json)
                : null
            )
                .whereType<ExpenseTypeStats>()
                .toList();

            if (kDebugMode) {
              print('⭐️ Parsed Expense Type Stats: $stats');
            }
            return stats;
          } else {
            print('⭐️ Expense Type Stats Data is not a List');
            return [];
          }
        }

        // If success is false, print the message
        if (kDebugMode) {
          print('⭐️ Expense Type Stats API Error: ${data['message']}');
        }
        throw Exception(data['message'] ?? 'Failed to load expense type statistics');
      }

      // If status code is not 200, throw an exception with details
      throw Exception('Failed to load expense type statistics. Status: ${response.statusCode}. Body: ${response.body}');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('⭐️ Error in getExpenseTypeStats: $e');
      }
      if (kDebugMode) {
        print('⭐️ Stack Trace: $stackTrace');
      }

      // Rethrow the exception to be handled by the caller
      rethrow;
    }
  }

  // POST /expenses
  Future<Expense> createExpense(Expense expense) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: headers,
        body: json.encode(expense.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Expense.fromJson(data['data']);
        }
        throw Exception(data['message'] ?? 'Failed to create expense');
      }
      throw Exception('Failed to create expense. Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating expense: ${e.toString()}');
    }
  }

  // GET /expenses/{id}
  Future<Expense> getExpense(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Expense.fromJson(data['data']);
        }
        throw Exception(data['message'] ?? 'Failed to load expense');
      }
      throw Exception('Failed to load expense. Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching expense: ${e.toString()}');
    }
  }

  // PUT /expenses/{id}
  Future<Expense> updateExpense(int id, Expense expense) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: headers,
        body: json.encode(expense.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Expense.fromJson(data['data']);
        }
        throw Exception(data['message'] ?? 'Failed to update expense');
      }
      throw Exception('Failed to update expense. Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating expense: ${e.toString()}');
    }
  }

  // PATCH /expenses/{id}
  Future<Expense> partialUpdateExpense(int id, Map<String, dynamic> updates) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: headers,
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Expense.fromJson(data['data']);
        }
        throw Exception(data['message'] ?? 'Failed to update expense');
      }
      throw Exception('Failed to update expense. Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating expense: ${e.toString()}');
    }
  }

  // DELETE /expenses/{id}
  Future<void> deleteExpense(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete expense. Status: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (!data['success']) {
        throw Exception(data['message'] ?? 'Failed to delete expense');
      }
    } catch (e) {
      throw Exception('Error deleting expense: ${e.toString()}');
    }
  }

  // GET /expenses/statistics
  Future<ExpenseStatistics> getStatistics({
    int? shopId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final actualShopId = shopId ?? await _getShopId();

    final queryParams = {
      'shop_id': actualShopId.toString(),
      if (startDate != null) 'date_from': startDate.toString().substring(0, startDate.toString().indexOf(" ")),
      if (endDate != null) 'date_to': endDate.toString().substring(0, endDate.toString().indexOf(" ")),
    };

    final uri = Uri.parse('$baseUrl/expenses/statistics').replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return ExpenseStatistics.fromJson(data['data']);
        }
        throw Exception(data['message'] ?? 'Failed to load statistics');
      }
      throw Exception('Failed to load statistics. Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching statistics: ${e.toString()}');
    }
  }
}

// Providers
final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService();
});

final expenseTypeStatsProvider = FutureProvider.family<List<ExpenseTypeStats>, ExpenseTypeStatsParams>((ref, params) async {
  final expenseService = ref.read(expenseServiceProvider);
  return expenseService.getExpenseTypeStats(
    startDate: params.startDate,
    endDate: params.endDate,
  );
});
