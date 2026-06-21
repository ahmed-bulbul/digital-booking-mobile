import '../models/auth_models.dart';
import '../models/search_models.dart';
import 'api_service.dart';
import '../../core/constants/api_constants.dart';

class SearchService {
  final ApiService _api;
  SearchService(this._api);

  Future<List<RouteOption>> getRoutes() async {
    final data = await _api.get(ApiConstants.routesPublic);
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => RouteOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SearchResult>> search({
    required int routeId,
    required DateTime travelDate,
    int page = 0,
    int size = 20,
    String? sortBy,
  }) async {
    final dateStr =
        '${travelDate.year}-${travelDate.month.toString().padLeft(2, '0')}-${travelDate.day.toString().padLeft(2, '0')}';
    final body = <String, dynamic>{
      'routeId': routeId,
      'travelDate': dateStr,
      'page': page,
      'size': size,
      if (sortBy != null) 'sortBy': sortBy,
    };
    final data = await _api.post(ApiConstants.search, body);
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => SearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ScheduleInventoryLayout> getInventoryLayout(int scheduleId) async {
    final data = await _api.get('${ApiConstants.schedules}/$scheduleId/inventory');
    return ScheduleInventoryLayout.fromJson(data['data'] as Map<String, dynamic>);
  }
}
