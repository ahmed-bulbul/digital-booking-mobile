import 'package:flutter/foundation.dart';
import '../data/models/auth_models.dart';
import '../data/models/search_models.dart';
import '../data/services/search_service.dart';

class SearchProvider extends ChangeNotifier {
  final SearchService _searchService;

  List<RouteOption> _routes = [];
  List<SearchResult> _results = [];
  bool _loadingRoutes = false;
  bool _searching = false;
  String? _routesError;
  String? _error;

  RouteOption? _selectedRoute;
  DateTime _travelDate = DateTime.now().add(const Duration(days: 1));
  String? _sortBy;

  SearchProvider(this._searchService);

  List<RouteOption> get routes => _routes;
  List<SearchResult> get results => _results;
  bool get loadingRoutes => _loadingRoutes;
  bool get searching => _searching;
  String? get routesError => _routesError;
  String? get error => _error;
  RouteOption? get selectedRoute => _selectedRoute;
  DateTime get travelDate => _travelDate;
  String? get sortBy => _sortBy;

  Future<void> loadRoutes({bool forceReload = false}) async {
    if (_routes.isNotEmpty && !forceReload) return;
    _loadingRoutes = true;
    _routesError = null;
    notifyListeners();
    try {
      debugPrint('[SearchProvider] Loading routes...');
      _routes = await _searchService.getRoutes();
      debugPrint('[SearchProvider] Loaded ${_routes.length} routes');
    } catch (e, st) {
      debugPrint('[SearchProvider] loadRoutes error: $e\n$st');
      _routesError = e.toString();
    } finally {
      _loadingRoutes = false;
      notifyListeners();
    }
  }

  void setRoute(RouteOption route) {
    _selectedRoute = route;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _travelDate = date;
    notifyListeners();
  }

  void setSortBy(String? value) {
    _sortBy = value;
    notifyListeners();
  }

  Future<void> search() async {
    if (_selectedRoute == null) return;
    _searching = true;
    _error = null;
    _results = [];
    notifyListeners();
    try {
      _results = await _searchService.search(
        routeId: _selectedRoute!.routeId,
        travelDate: _travelDate,
        sortBy: _sortBy,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _searching = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _results = [];
    _error = null;
    notifyListeners();
  }
}
