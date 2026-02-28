import 'dart:collection';

import 'package:myanmar_calendar_dart/src/models/astro_info.dart';
import 'package:myanmar_calendar_dart/src/models/complete_date.dart';
import 'package:myanmar_calendar_dart/src/models/custom_holiday.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_info.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_date.dart';
import 'package:myanmar_calendar_dart/src/models/shan_date.dart';
import 'package:myanmar_calendar_dart/src/models/western_date.dart';

/// Typed callback contract used to warm up complete-date cache entries.
typedef CompleteDateResolver = CompleteDate Function(DateTime dateTime);

/// Cache configuration options
class CacheConfig {
  /// Create a new [CacheConfig] instance
  const CacheConfig({
    this.maxCompleteDateCacheSize = 100,
    this.maxMyanmarDateCacheSize = 200,
    this.maxShanDateCacheSize = 200,
    this.maxWesternDateCacheSize = 200,
    this.maxAstroInfoCacheSize = 150,
    this.maxHolidayInfoCacheSize = 150,
    this.enableCaching = true,
    this.cacheTTL = 0, // No expiration by default
  }); // 1 hour

  /// High-performance configuration (more memory usage)
  const CacheConfig.highPerformance()
    : maxCompleteDateCacheSize = 500,
      maxMyanmarDateCacheSize = 1000,
      maxShanDateCacheSize = 1000,
      maxWesternDateCacheSize = 1000,
      maxAstroInfoCacheSize = 500,
      maxHolidayInfoCacheSize = 500,
      enableCaching = true,
      cacheTTL = 0;

  /// Disable all caching
  const CacheConfig.disabled()
    : maxCompleteDateCacheSize = 0,
      maxMyanmarDateCacheSize = 0,
      maxShanDateCacheSize = 0,
      maxWesternDateCacheSize = 0,
      maxAstroInfoCacheSize = 0,
      maxHolidayInfoCacheSize = 0,
      enableCaching = false,
      cacheTTL = 0;

  /// Memory-efficient configuration
  const CacheConfig.memoryEfficient()
    : maxCompleteDateCacheSize = 30,
      maxMyanmarDateCacheSize = 50,
      maxShanDateCacheSize = 50,
      maxWesternDateCacheSize = 50,
      maxAstroInfoCacheSize = 40,
      maxHolidayInfoCacheSize = 40,
      enableCaching = true,
      cacheTTL = 3600;

  /// Maximum number of CompleteDate objects to cache
  final int maxCompleteDateCacheSize;

  /// Maximum number of MyanmarDate objects to cache
  final int maxMyanmarDateCacheSize;

  /// Maximum number of ShanDate objects to cache
  final int maxShanDateCacheSize;

  /// Maximum number of WesternDate objects to cache
  final int maxWesternDateCacheSize;

  /// Maximum number of AstroInfo objects to cache
  final int maxAstroInfoCacheSize;

  /// Maximum number of HolidayInfo objects to cache
  final int maxHolidayInfoCacheSize;

  /// Whether to enable caching
  final bool enableCaching;

  /// Cache time-to-live in seconds (0 = no expiration)
  final int cacheTTL;

  @override
  String toString() {
    return 'CacheConfig(maxCompleteDateCacheSize: $maxCompleteDateCacheSize, maxMyanmarDateCacheSize: $maxMyanmarDateCacheSize, maxShanDateCacheSize: $maxShanDateCacheSize, maxWesternDateCacheSize: $maxWesternDateCacheSize, maxAstroInfoCacheSize: $maxAstroInfoCacheSize, maxHolidayInfoCacheSize: $maxHolidayInfoCacheSize, enableCaching: $enableCaching, cacheTTL: $cacheTTL)';
  }
}

/// Cache entry with timestamp for TTL support
class _CacheEntry<T> {
  _CacheEntry(this.value) : timestamp = DateTime.now();
  final T value;
  final DateTime timestamp;

  bool isExpired(int ttl) {
    if (ttl == 0) return false;
    return DateTime.now().difference(timestamp).inSeconds > ttl;
  }
}

/// Typed statistics for a single cache bucket.
class CacheBucketStatistics {
  /// Creates statistics for one cache bucket.
  const CacheBucketStatistics({
    required this.size,
    required this.maxSize,
    required this.ttl,
    required this.enabled,
  });

  /// Current number of entries in this cache bucket.
  final int size;

  /// Maximum allowed entries in this cache bucket.
  final int maxSize;

  /// Time-to-live in seconds (0 means no expiration).
  final int ttl;

  /// Whether this cache bucket is enabled.
  final bool enabled;

  /// Utilization percentage (`size / maxSize * 100`).
  double get utilizationPercent => maxSize > 0 ? (size / maxSize * 100) : 0.0;

  /// Converts this statistics object to a serializable map.
  Map<String, Object> toMap() {
    return {
      'size': size,
      'maxSize': maxSize,
      'utilizationPercent': utilizationPercent.toStringAsFixed(2),
      'ttl': ttl,
      'enabled': enabled,
    };
  }
}

/// Typed statistics snapshot for all caches managed by [CalendarCache].
class CalendarCacheStatistics {
  /// Creates a typed snapshot of all cache statistics.
  const CalendarCacheStatistics({
    required this.enabled,
    required this.hits,
    required this.misses,
    required this.completeDate,
    required this.myanmarDate,
    required this.shanDate,
    required this.westernDate,
    required this.astroInfo,
    required this.holidayInfo,
  });

  /// Whether caching is enabled globally for this cache instance.
  final bool enabled;

  /// Number of cache hits observed.
  final int hits;

  /// Number of cache misses observed.
  final int misses;

  /// Complete-date cache bucket statistics.
  final CacheBucketStatistics completeDate;

  /// Myanmar-date cache bucket statistics.
  final CacheBucketStatistics myanmarDate;

  /// Shan-date cache bucket statistics.
  final CacheBucketStatistics shanDate;

  /// Western-date cache bucket statistics.
  final CacheBucketStatistics westernDate;

  /// Astro-info cache bucket statistics.
  final CacheBucketStatistics astroInfo;

  /// Holiday-info cache bucket statistics.
  final CacheBucketStatistics holidayInfo;

  /// Total cache requests (`hits + misses`).
  int get totalRequests => hits + misses;

  /// Hit ratio (`hits / totalRequests`).
  double get hitRate => totalRequests == 0 ? 0.0 : (hits / totalRequests);

  /// Sum of entries across all cache buckets.
  int get totalMemoryEntries =>
      completeDate.size +
      myanmarDate.size +
      shanDate.size +
      westernDate.size +
      astroInfo.size +
      holidayInfo.size;

  /// Converts this statistics object to a serializable map.
  Map<String, Object> toMap() {
    return {
      'enabled': enabled,
      'hits': hits,
      'misses': misses,
      'total_requests': totalRequests,
      'hit_rate_percent': (hitRate * 100).toStringAsFixed(2),
      'caches': {
        'complete_date': completeDate.toMap(),
        'myanmar_date': myanmarDate.toMap(),
        'shan_date': shanDate.toMap(),
        'western_date': westernDate.toMap(),
        'astro_info': astroInfo.toMap(),
        'holiday_info': holidayInfo.toMap(),
      },
      'total_memory_entries': totalMemoryEntries,
    };
  }
}

/// LRU (Least Recently Used) Cache implementation
class _LRUCache<K, V> {
  _LRUCache(this.maxSize, this.ttl, {this.enabled = true});
  final int maxSize;
  final int ttl;
  final bool enabled;
  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();

  V? get(K key) {
    // If caching is disabled, always return null
    if (!enabled || maxSize == 0) return null;

    final entry = _cache.remove(key);
    if (entry == null) return null;

    // Check if expired
    if (entry.isExpired(ttl)) {
      return null;
    }

    // Reinsert to move this key to MRU position.
    _cache[key] = entry;

    return entry.value;
  }

  void put(K key, V value) {
    // If caching is disabled, don't store anything
    if (!enabled || maxSize == 0) return;

    // Remove if already exists
    _cache.remove(key);

    // Add new entry
    _cache[key] = _CacheEntry(value);

    // Evict LRU if necessary.
    while (_cache.length > maxSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  int get size => _cache.length;

  bool containsKey(K key) => _cache.containsKey(key);

  /// Get typed cache statistics.
  CacheBucketStatistics getStats() {
    return CacheBucketStatistics(
      size: _cache.length,
      maxSize: maxSize,
      ttl: ttl,
      enabled: enabled,
    );
  }
}

/// Centralized cache manager for Myanmar Calendar
///
/// This class manages caching for all calendar operations.
/// It can work in two modes:
/// 1. Global shared mode - All services share one cache instance
/// 2. Independent mode - Each service has its own cache
class CalendarCache {
  /// Create a new independent cache instance
  /// Use this for testing or when you need isolated caching
  factory CalendarCache.independent({CacheConfig? config}) {
    return CalendarCache._internal(config ?? const CacheConfig());
  }

  // ============================================================================
  // CONSTRUCTORS
  // ============================================================================

  /// Private constructor for creating cache instances
  CalendarCache._internal(CacheConfig config) {
    _config = config;
    _initializeCaches();
  }

  /// Get or create global shared cache
  factory CalendarCache.global() {
    _globalCache ??= CalendarCache._internal(const CacheConfig());
    return _globalCache!;
  }
  // ============================================================================
  // GLOBAL SHARED CACHE
  // ============================================================================

  /// Global shared cache instance
  static CalendarCache? _globalCache;

  /// Configure global cache with new settings
  static void configureGlobal(CacheConfig config) {
    _globalCache = CalendarCache._internal(config);
  }

  /// Check if global cache exists
  static bool get hasGlobal => _globalCache != null;

  /// Clear global cache instance (mainly for testing)
  static void resetGlobal() {
    _globalCache?.clearAll();
    _globalCache = null;
  }

  // ============================================================================
  // INSTANCE PROPERTIES
  // ============================================================================

  late CacheConfig _config;

  // Individual caches
  late _LRUCache<String, CompleteDate> _completeDateCache;
  late _LRUCache<String, MyanmarDate> _myanmarDateCache;
  late _LRUCache<String, ShanDate> _shanDateCache;
  late _LRUCache<String, WesternDate> _westernDateCache;
  late _LRUCache<String, AstroInfo> _astroInfoCache;
  late _LRUCache<String, HolidayInfo> _holidayInfoCache;

  // Statistics
  int _hits = 0;
  int _misses = 0;

  void _initializeCaches() {
    _completeDateCache = _LRUCache(
      _config.maxCompleteDateCacheSize,
      _config.cacheTTL,
      enabled: _config.enableCaching,
    );
    _myanmarDateCache = _LRUCache(
      _config.maxMyanmarDateCacheSize,
      _config.cacheTTL,
      enabled: _config.enableCaching,
    );
    _shanDateCache = _LRUCache(
      _config.maxShanDateCacheSize,
      _config.cacheTTL,
      enabled: _config.enableCaching,
    );
    _westernDateCache = _LRUCache(
      _config.maxWesternDateCacheSize,
      _config.cacheTTL,
      enabled: _config.enableCaching,
    );
    _astroInfoCache = _LRUCache(
      _config.maxAstroInfoCacheSize,
      _config.cacheTTL,
      enabled: _config.enableCaching,
    );
    _holidayInfoCache = _LRUCache(
      _config.maxHolidayInfoCacheSize,
      _config.cacheTTL,
      enabled: _config.enableCaching,
    );
  }

  // ============================================================================
  // CACHE OPERATIONS
  // ============================================================================

  /// Get cached CompleteDate
  CompleteDate? getCompleteDate(
    DateTime dateTime, {
    List<CustomHoliday>? customHolidays,
    String namespace = '',
  }) {
    if (!_config.enableCaching) {
      _misses++;
      return null;
    }

    final key = _generateCompleteDateKey(
      dateTime,
      customHolidays,
      namespace: namespace,
    );
    final cached = _completeDateCache.get(key);

    if (cached != null) {
      _hits++;
      return cached;
    }

    _misses++;
    return null;
  }

  /// Cache CompleteDate
  void putCompleteDate(
    DateTime dateTime,
    CompleteDate completeDate, {
    List<CustomHoliday>? customHolidays,
    String namespace = '',
  }) {
    if (!_config.enableCaching) return;
    final key = _generateCompleteDateKey(
      dateTime,
      customHolidays,
      namespace: namespace,
    );
    _completeDateCache.put(key, completeDate);
  }

  /// Get cached MyanmarDate
  MyanmarDate? getMyanmarDate(double julianDayNumber, {String namespace = ''}) {
    if (!_config.enableCaching) {
      _misses++;
      return null;
    }

    final key = _namespaceKey(julianDayNumber.toStringAsFixed(6), namespace);
    final cached = _myanmarDateCache.get(key);

    if (cached != null) {
      _hits++;
      return cached;
    }

    _misses++;
    return null;
  }

  /// Cache MyanmarDate
  void putMyanmarDate(
    double julianDayNumber,
    MyanmarDate myanmarDate, {
    String namespace = '',
  }) {
    if (!_config.enableCaching) return;
    final key = _namespaceKey(julianDayNumber.toStringAsFixed(6), namespace);
    _myanmarDateCache.put(key, myanmarDate);
  }

  /// Get cached WesternDate
  WesternDate? getWesternDate(double julianDayNumber, {String namespace = ''}) {
    if (!_config.enableCaching) {
      _misses++;
      return null;
    }

    final key = _namespaceKey(julianDayNumber.toStringAsFixed(6), namespace);
    final cached = _westernDateCache.get(key);

    if (cached != null) {
      _hits++;
      return cached;
    }

    _misses++;
    return null;
  }

  /// Cache WesternDate
  void putWesternDate(
    double julianDayNumber,
    WesternDate westernDate, {
    String namespace = '',
  }) {
    if (!_config.enableCaching) return;
    final key = _namespaceKey(julianDayNumber.toStringAsFixed(6), namespace);
    _westernDateCache.put(key, westernDate);
  }

  /// Get cached ShanDate
  ShanDate? getShanDate(double julianDayNumber, {String namespace = ''}) {
    if (!_config.enableCaching) {
      _misses++;
      return null;
    }

    final key = _namespaceKey(julianDayNumber.toStringAsFixed(6), namespace);
    final cached = _shanDateCache.get(key);

    if (cached != null) {
      _hits++;
      return cached;
    }

    _misses++;
    return null;
  }

  /// Cache ShanDate
  void putShanDate(
    double julianDayNumber,
    ShanDate shanDate, {
    String namespace = '',
  }) {
    if (!_config.enableCaching) return;
    final key = _namespaceKey(julianDayNumber.toStringAsFixed(6), namespace);
    _shanDateCache.put(key, shanDate);
  }

  /// Get cached AstroInfo
  AstroInfo? getAstroInfo(MyanmarDate myanmarDate, {String namespace = ''}) {
    if (!_config.enableCaching) {
      _misses++;
      return null;
    }

    final key = _namespaceKey(_generateMyanmarDateKey(myanmarDate), namespace);
    final cached = _astroInfoCache.get(key);

    if (cached != null) {
      _hits++;
      return cached;
    }

    _misses++;
    return null;
  }

  /// Cache AstroInfo
  void putAstroInfo(
    MyanmarDate myanmarDate,
    AstroInfo astroInfo, {
    String namespace = '',
  }) {
    if (!_config.enableCaching) return;
    final key = _namespaceKey(_generateMyanmarDateKey(myanmarDate), namespace);
    _astroInfoCache.put(key, astroInfo);
  }

  /// Get cached HolidayInfo
  HolidayInfo? getHolidayInfo(
    MyanmarDate myanmarDate, {
    String namespace = '',
  }) {
    if (!_config.enableCaching) {
      _misses++;
      return null;
    }

    final key = _generateMyanmarDateKey(myanmarDate);
    return getHolidayInfoByKey(key, namespace: namespace);
  }

  /// Get cached HolidayInfo by key
  HolidayInfo? getHolidayInfoByKey(String key, {String namespace = ''}) {
    if (!_config.enableCaching) {
      _misses++;
      return null;
    }

    final namespacedKey = _namespaceKey(key, namespace);
    final cached = _holidayInfoCache.get(namespacedKey);

    if (cached != null) {
      _hits++;
      return cached;
    }

    _misses++;
    return null;
  }

  /// Cache HolidayInfo
  void putHolidayInfo(
    MyanmarDate myanmarDate,
    HolidayInfo holidayInfo, {
    String namespace = '',
  }) {
    if (!_config.enableCaching) return;
    final key = _generateMyanmarDateKey(myanmarDate);
    putHolidayInfoByKey(key, holidayInfo, namespace: namespace);
  }

  /// Cache HolidayInfo by key
  void putHolidayInfoByKey(
    String key,
    HolidayInfo holidayInfo, {
    String namespace = '',
  }) {
    if (!_config.enableCaching) return;
    _holidayInfoCache.put(_namespaceKey(key, namespace), holidayInfo);
  }

  String _generateMyanmarDateKey(MyanmarDate myanmarDate) {
    return '${myanmarDate.year}-${myanmarDate.month}-${myanmarDate.day}';
  }

  String _generateCompleteDateKey(
    DateTime dateTime,
    List<CustomHoliday>? customHolidays, {
    String namespace = '',
  }) {
    final dateKey = _namespaceKey(
      dateTime.toUtc().microsecondsSinceEpoch.toString(),
      namespace,
    );
    if (customHolidays == null || customHolidays.isEmpty) return dateKey;

    final holidayDescriptors =
        customHolidays.map((h) => h.cacheDescriptor).toList()..sort();
    return '$dateKey|${holidayDescriptors.join(',')}';
  }

  String _namespaceKey(String key, String namespace) {
    if (namespace == '') return key;
    return '$namespace|$key';
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  /// Clear all caches
  void clearAll() {
    _completeDateCache.clear();
    _myanmarDateCache.clear();
    _shanDateCache.clear();
    _westernDateCache.clear();
    _astroInfoCache.clear();
    _holidayInfoCache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Clear CompleteDate cache only
  void clearCompleteDateCache() => _completeDateCache.clear();

  /// Clear MyanmarDate cache only
  void clearMyanmarDateCache() => _myanmarDateCache.clear();

  /// Clear ShanDate cache only
  void clearShanDateCache() => _shanDateCache.clear();

  /// Clear WesternDate cache only
  void clearWesternDateCache() => _westernDateCache.clear();

  /// Clear AstroInfo cache only
  void clearAstroInfoCache() => _astroInfoCache.clear();

  /// Clear HolidayInfo cache only
  void clearHolidayInfoCache() => _holidayInfoCache.clear();

  /// Warm up cache with common dates
  void warmUp({
    required CompleteDateResolver resolveCompleteDate,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (!_config.enableCaching) return;

    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now().add(const Duration(days: 60));

    var currentDate = start;
    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      resolveCompleteDate(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  // ============================================================================
  // STATISTICS
  // ============================================================================

  /// Get hit rate.
  double get hitRate {
    final total = _hits + _misses;
    if (total == 0) return 0;
    return _hits / total;
  }

  /// Get typed cache statistics snapshot.
  CalendarCacheStatistics getTypedStatistics() {
    return CalendarCacheStatistics(
      enabled: _config.enableCaching,
      hits: _hits,
      misses: _misses,
      completeDate: _completeDateCache.getStats(),
      myanmarDate: _myanmarDateCache.getStats(),
      shanDate: _shanDateCache.getStats(),
      westernDate: _westernDateCache.getStats(),
      astroInfo: _astroInfoCache.getStats(),
      holidayInfo: _holidayInfoCache.getStats(),
    );
  }

  /// Legacy map-based statistics for backward compatibility.
  Map<String, dynamic> getStatistics() {
    return getTypedStatistics().toMap();
  }

  /// Reset statistics
  void resetStatistics() {
    _hits = 0;
    _misses = 0;
  }

  /// Get [CacheConfig] instance
  CacheConfig get config => _config;

  /// Check whether cache is enabled or not.
  bool get isEnabled => _config.enableCaching;
}
