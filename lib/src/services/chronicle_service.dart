import 'package:myanmar_calendar_dart/src/core/calendar_config.dart';
import 'package:myanmar_calendar_dart/src/localization/language.dart';
import 'package:myanmar_calendar_dart/src/models/chronicle_models.dart';
import 'package:myanmar_calendar_dart/src/utils/chronicles_constants.dart';

/// Chronicle service for loading and managing chronicle data.
class ChronicleService {
  /// Create a new Chronicle service.
  ChronicleService({required this.config, required this.language});

  ///
  final CalendarConfig config;

  /// Language of the chronicle.
  final Language language;

  /// List of entries.
  List<ChronicleEntryData>? _entries; // same reference to const list

  /// List of dynasties.
  List<DynastyData>? _dynasties;

  /// Indices built on first use.
  Map<String, List<ChronicleEntryData>>? _dynastyToEntries;
  List<DynastyData>? _sortedDynasties;
  Map<String, DynastyData>? _dynastiesById;

  /// Ensure the data is loaded.
  void _ensureLoaded() {
    _entries ??= kChronicleEntries;
    _dynasties ??= kDynasties;

    _sortedDynasties ??= List<DynastyData>.unmodifiable(
      List<DynastyData>.from(_dynasties!)
        ..sort((a, b) => a.startJdn.compareTo(b.startJdn)),
    );
    _dynastiesById ??= {for (final d in _dynasties!) d.id: d};

    if (_dynastyToEntries == null) {
      _dynastyToEntries = <String, List<ChronicleEntryData>>{};
      for (final e in _entries!) {
        if (e.dynastyId == null) continue;
        (_dynastyToEntries![e.dynastyId!] ??= <ChronicleEntryData>[]).add(e);
      }
      for (final list in _dynastyToEntries!.values) {
        list.sort((a, b) => a.startJdn.compareTo(b.startJdn));
      }
    }
  }

  /// Get entries covering the day of [jdn].
  List<ChronicleEntryData> byJdn(double jdn) {
    _ensureLoaded();
    // A few hundred entries: a linear scan is cheaper than an index.
    final result = <ChronicleEntryData>[];
    for (final e in _entries!) {
      if (e.includesJdn(jdn)) result.add(e);
    }
    return result;
  }

  /// Get dynasty by Julian day number.
  DynastyData? dynastyForJdn(double jdn) {
    _ensureLoaded();
    for (final d in _dynasties!) {
      if (jdn >= d.startJdn && jdn <= d.endJdn) return d;
    }
    return null;
  }

  /// Get entries for a given dynasty ID (ordered by start date).
  List<ChronicleEntryData> entriesForDynasty(String dynastyId) {
    _ensureLoaded();
    return List<ChronicleEntryData>.from(
      _dynastyToEntries?[dynastyId] ?? const <ChronicleEntryData>[],
    );
  }

  /// Get chronicle entries covering any day from [startJdn] to [endJdn].
  ///
  /// An entry without an end date is a one-day event.
  List<ChronicleEntryData> betweenJdn(double startJdn, double endJdn) {
    _ensureLoaded();
    final result = <ChronicleEntryData>[];
    for (final e in _entries!) {
      if (e.overlapsJdn(startJdn, endJdn)) result.add(e);
    }
    result.sort((x, y) => x.startJdn.compareTo(y.startJdn));
    return result;
  }

  /// List all dynasties (ordered by start date).
  List<DynastyData> allDynasties() {
    _ensureLoaded();
    return _sortedDynasties!;
  }

  /// Lookup a dynasty by ID.
  DynastyData? dynastyById(String dynastyId) {
    _ensureLoaded();
    return _dynastiesById![dynastyId];
  }
}
