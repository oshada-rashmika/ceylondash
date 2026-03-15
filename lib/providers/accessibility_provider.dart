import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class AccessibilityProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<String> _activeNeeds = [];

  List<String> get activeNeeds => List.unmodifiable(_activeNeeds);

  bool get isVisuallyImpaired => _activeNeeds.contains('Visually Impaired');
  bool get hasColorBlindness => _activeNeeds.contains('Color Blindness');
  bool get needsNeuroSupport => _activeNeeds.contains('Neurodivergent Support');
  bool get isDeafOrHoH => _activeNeeds.contains('Deaf / Hard of Hearing');
  bool get hasMobilityNeeds => _activeNeeds.contains('Mobility Needs');

  Future<void> loadNeeds(String uid) async {
    try {
      final user = await _db.getUser(uid);
      final needs = user?.accessibilityNeeds ?? [];
      _activeNeeds = List<String>.from(needs);
      notifyListeners();
    } catch (_) {}
  }

  void updateNeeds(List<String> needs) {
    _activeNeeds = List<String>.from(needs);
    notifyListeners();
  }

  void clear() {
    _activeNeeds = [];
    notifyListeners();
  }
}
