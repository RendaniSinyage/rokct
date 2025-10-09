import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/core/utils/time_service.dart';
import 'package:admin_desktop/src/models/response/close_day_response.dart';
import 'package:admin_desktop/src/models/response/table_info_response.dart';
import 'package:admin_desktop/src/models/response/table_statistic_response.dart';
import 'package:admin_desktop/src/models/response/working_day_response.dart';
import 'package:admin_desktop/src/repository/table_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import '../../models/data/table_data.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../../models/response/table_bookings_response.dart';
import '../../models/response/table_response.dart';

class TableRepositoryIml extends TableRepository {
  @override
  Future<ApiResult<BookingsResponse>> getBookings({int? page}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_all_bookings',
        queryParameters: {
          'limit_start': (page ?? 1) - 1 * 100,
          'limit_page_length': 100,
        },
      );
      return ApiResult.success(data: BookingsResponse.fromJson(response.data));
    } catch (e) {
      debugPrint('==> get getBookings failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> setBookings({
    int? bookingId,
    int? tableId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.create_booking',
        data: {
          'booking_id': bookingId,
          'end_date': TimeService.dateFormatYMDHm(endDate ?? DateTime.now()),
          'start_date':
              TimeService.dateFormatYMDHm(startDate ?? DateTime.now()),
          "table_id": tableId
        },
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> get setBookings failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<WorkingDayResponse>> getWorkingDay() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_seller_shop_working_days',
      );
      return ApiResult.success(
          data: WorkingDayResponse.fromJson(response.data));
    } catch (e) {
      debugPrint('==> get getWorkingDay failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<CloseDayResponse>> getCloseDay() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_seller_shop_closed_days',
      );
      return ApiResult.success(data: CloseDayResponse.fromJson(response.data));
    } catch (e) {
      debugPrint('==> getCloseDay failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<TableInfoResponse>> getTableInfo(int id) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_booking',
        queryParameters: {'id': id},
      );
      return ApiResult.success(data: TableInfoResponse.fromJson(response.data));
    } catch (e) {
      debugPrint('==> getTableInfo failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult> changeOrderStatus(
      {required String status, required int id}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.update_booking',
        data: {
          'booking_name': id,
          'booking_data': {'status': status}
        },
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> changeOrderStatus failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  // NOTE: The following methods are not supported or relevant for the POS app.
  // - createNewSection
  // - getSection
  // - createNewTable
  // - getTables
  // - getTableOrders
  // - deleteSection
  // - deleteTable
  // - disableDates
  // - getStatistic

  @override
  Future<ApiResult<ShopSection>> createNewSection({required String name, required num area}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<ShopSectionResponse>> getSection({int? page, String? query}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult> createNewTable({required TableModel tableModel}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<TableResponse>> getTables({int? page, int? shopSectionId, String? type, String? query, DateTime? from, DateTime? to}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<TableBookingResponse>> getTableOrders({int? page, int? id, String? type, DateTime? from, DateTime? to}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<TableResponse>> deleteSection(int id) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<TableResponse>> deleteTable(int id) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<List<DisableDates>>> disableDates({required DateTime dateTime, required int? id}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<TableStatisticResponse>> getStatistic({DateTime? from, DateTime? to}) {
    throw UnimplementedError();
  }
}