import 'package:flutter/foundation.dart';

import '../models/itinerary.dart';
import '../models/stop.dart';

/// Modalità dell'app.
/// - normale: navigazione sobria, nessun racconto audio.
/// - turismo: esperienza turistica con guida audio selezionabile.
enum AppMode { normale, turismo }

/// Stato globale leggero dell'app (via provider).
class AppState extends ChangeNotifier {
  final Itinerary itinerary;

  AppMode _mode = AppMode.normale;
  bool _experienceStarted = false;
  int _selectedStopIndex = 0;

  AppState(this.itinerary);

  AppMode get mode => _mode;
  bool get isTourism => _mode == AppMode.turismo;
  bool get experienceStarted => _experienceStarted;
  int get selectedStopIndex => _selectedStopIndex;
  Stop get selectedStop => itinerary.stops[_selectedStopIndex];
  bool get hasPrev => _selectedStopIndex > 0;
  bool get hasNext => _selectedStopIndex < itinerary.stops.length - 1;

  void enterTourism() {
    _mode = AppMode.turismo;
    notifyListeners();
  }

  void exitTourism() {
    _mode = AppMode.normale;
    _experienceStarted = false;
    notifyListeners();
  }

  void startExperience() {
    _mode = AppMode.turismo;
    _experienceStarted = true;
    _selectedStopIndex = 0;
    notifyListeners();
  }

  void selectStop(int index) {
    _selectedStopIndex = index.clamp(0, itinerary.stops.length - 1);
    notifyListeners();
  }

  void selectStopById(String id) {
    final i = itinerary.stops.indexWhere((s) => s.id == id);
    if (i >= 0) selectStop(i);
  }

  void nextStop() {
    if (hasNext) selectStop(_selectedStopIndex + 1);
  }

  void prevStop() {
    if (hasPrev) selectStop(_selectedStopIndex - 1);
  }
}
