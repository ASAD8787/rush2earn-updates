import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';

import '../models/daily_steps.dart';
import '../models/walk_stats.dart';
import '../services/pedometer_service.dart';
import '../services/relayer_service.dart';
import '../services/storage_service.dart';
import '../services/wallet_service.dart';
import '../config/web3_config.dart';

class WalkController extends ChangeNotifier {
  WalkController({
    required StorageService storageService,
    required PedometerService pedometerService,
    required WalletService walletService,
    required RelayerService relayerService,
  }) : _storageService = storageService,
       _pedometerService = pedometerService,
       _walletService = walletService,
       _relayerService = relayerService;

  final StorageService _storageService;
  final PedometerService _pedometerService;
  final WalletService _walletService;
  final RelayerService _relayerService;

  WalkStats _stats = const WalkStats(
    totalSteps: 0,
    isTracking: false,
    liveSessionSteps: 0,
    claimedSteps: 0,
  );
  WalkStats get stats => _stats;
  Map<String, int> _dailySteps = <String, int>{};
  static const double _withdrawBaseFee = 0.00012;
  String get rushTokenContractAddress => Web3Config.rushTokenContract;
  double get withdrawBaseFee => _withdrawBaseFee;
  bool get isWalletConnected => _walletService.isConnected;
  String? get walletAddress => _walletService.session?.address;
  WalletProviderType? get walletProvider => _walletService.session?.provider;
  bool _isSubmittingTx = false;
  bool get isSubmittingTx => _isSubmittingTx;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianSubscription;
  int? _sessionStartSensorSteps;
  int? _latestSensorSteps;
  int _sessionStartTotalSteps = 0;
  int _sessionAccumulatedSteps = 0;
  bool _sensorReady = false;
  bool get sensorReady => _sensorReady;
  String _pedestrianState = 'unknown';
  String get pedestrianState => _pedestrianState;
  Timer? _persistDebounce;
  bool _isPersisting = false;
  bool _hasPendingPersist = false;
  static const List<String> _weekdayLabels = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  List<DailySteps> get last7DaysSteps {
    final today = DateTime.now();
    return List<DailySteps>.generate(7, (index) {
      final date = DateTime(today.year, today.month, today.day - (6 - index));
      final key = _dateKey(date);
      return DailySteps(
        dayLabel: _weekdayLabels[date.weekday - 1],
        steps: _dailySteps[key] ?? 0,
        isToday: _isSameDay(date, today),
      );
    });
  }

  Future<void> initialize() async {
    final totalSteps = await _storageService.loadTotalSteps();
    final claimedSteps = await _storageService.loadClaimedSteps();
    _stats = _stats.copyWith(
      totalSteps: totalSteps,
      claimedSteps: claimedSteps > totalSteps ? totalSteps : claimedSteps,
    );
    _dailySteps = await _storageService.loadDailySteps();
    _trimDailyHistory();
    _isLoading = false;
    notifyListeners();

    _stepSubscription = _pedometerService.stepCountStream.listen(
      _onStepCount,
      onError: (_) {
        _error = 'Step tracking unavailable on this device.';
        notifyListeners();
      },
      cancelOnError: false,
    );
    _pedestrianSubscription = _pedometerService.pedestrianStatusStream.listen(
      (event) {
        if (_pedestrianState != event.status) {
          _pedestrianState = event.status;
          notifyListeners();
        }
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  Future<bool> startTracking() async {
    _error = null;
    final hasPermission = await _pedometerService.requestActivityPermission();
    if (!hasPermission) {
      _error = 'Activity permission denied. Enable it to track steps.';
      notifyListeners();
      return false;
    }

    _sessionStartSensorSteps = null;
    _sessionStartSensorSteps = _latestSensorSteps;
    _sessionStartTotalSteps = _stats.totalSteps;
    _stats = _stats.copyWith(
      isTracking: true,
      liveSessionSteps: _sessionAccumulatedSteps,
    );
    notifyListeners();
    return true;
  }

  Future<void> stopTracking() async {
    _sessionAccumulatedSteps = _stats.liveSessionSteps;
    _sessionStartSensorSteps = null;
    _stats = _stats.copyWith(isTracking: false);
    notifyListeners();
  }

  Future<double> claimAllTokens() async {
    final claimable = _stats.claimableSteps;
    if (claimable <= 0) {
      return 0;
    }

    final claimedTotal = _stats.claimedSteps + claimable;
    _stats = _stats.copyWith(claimedSteps: claimedTotal);
    await _storageService.saveClaimedSteps(claimedTotal);
    notifyListeners();
    return claimable / 1000.0;
  }

  Future<String> connectWallet({
    required WalletProviderType provider,
    required String address,
  }) async {
    try {
      await _walletService.connect(provider: provider, address: address);
      notifyListeners();
      final providerLabel = provider == WalletProviderType.walletConnect
          ? 'WalletConnect'
          : 'Privy';
      return 'Connected with $providerLabel.';
    } on FormatException catch (e) {
      return e.message;
    } catch (_) {
      return 'Wallet connection failed.';
    }
  }

  Future<void> disconnectWallet() async {
    await _walletService.disconnect();
    notifyListeners();
  }

  String createBackupCode() {
    final payload = <String, dynamic>{
      'schema': 1,
      'totalSteps': _stats.totalSteps,
      'claimedSteps': _stats.claimedSteps,
      'dailySteps': _dailySteps,
      'createdAt': DateTime.now().toIso8601String(),
    };
    final bytes = utf8.encode(jsonEncode(payload));
    return base64UrlEncode(bytes);
  }

  Future<String> restoreFromBackupCode(String backupCode) async {
    try {
      final normalized = backupCode.trim();
      if (normalized.isEmpty) {
        return 'Backup code is empty.';
      }
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(normalized)),
      );
      final payload = jsonDecode(decoded);
      if (payload is! Map<String, dynamic>) {
        return 'Invalid backup format.';
      }

      final totalSteps = (payload['totalSteps'] as num?)?.toInt();
      final claimedSteps = (payload['claimedSteps'] as num?)?.toInt();
      final daily = payload['dailySteps'];
      if (totalSteps == null ||
          claimedSteps == null ||
          daily is! Map<String, dynamic>) {
        return 'Invalid backup payload.';
      }

      final restoredDaily = <String, int>{};
      daily.forEach((key, value) {
        if (value is num) {
          restoredDaily[key] = value.toInt();
        }
      });

      final safeClaimed = claimedSteps > totalSteps ? totalSteps : claimedSteps;
      _stats = _stats.copyWith(
        totalSteps: totalSteps < 0 ? 0 : totalSteps,
        claimedSteps: safeClaimed < 0 ? 0 : safeClaimed,
        isTracking: false,
        liveSessionSteps: 0,
      );
      _dailySteps = restoredDaily;
      _trimDailyHistory();
      _sessionAccumulatedSteps = 0;
      _sessionStartSensorSteps = null;
      _sessionStartTotalSteps = _stats.totalSteps;

      await Future.wait<void>([
        _storageService.saveTotalSteps(_stats.totalSteps),
        _storageService.saveClaimedSteps(_stats.claimedSteps),
        _storageService.saveDailySteps(_dailySteps),
      ]);
      notifyListeners();
      return 'Backup restored successfully.';
    } catch (_) {
      return 'Could not restore backup. Check your code and try again.';
    }
  }

  Future<String> sendTokens({
    required String recipient,
    required double amountTokens,
  }) async {
    if (!_walletService.isConnected || _walletService.session == null) {
      return 'Connect wallet first.';
    }
    if (recipient.trim().isEmpty) {
      return 'Enter recipient wallet address.';
    }
    final tokenUnits = (amountTokens * 1000).round();
    if (tokenUnits <= 0) {
      return 'Enter a valid amount (min 0.001 RUSH).';
    }
    if (tokenUnits > _stats.claimedSteps) {
      return 'Insufficient claimed RUSH balance.';
    }

    _isSubmittingTx = true;
    notifyListeners();
    final result = await _relayerService.sendTokenTransfer(
      fromAddress: _walletService.session!.address,
      toAddress: recipient.trim(),
      amountToken: amountTokens.toStringAsFixed(3),
      isWithdraw: false,
    );
    _isSubmittingTx = false;

    if (!result.success) {
      notifyListeners();
      return result.message;
    }

    final remaining = _stats.claimedSteps - tokenUnits;
    _stats = _stats.copyWith(claimedSteps: remaining);
    await _storageService.saveClaimedSteps(remaining);
    notifyListeners();
    final tx = result.txHash == null
        ? ''
        : ' Tx: ${_shortenHash(result.txHash!)}';
    return 'Sent ${amountTokens.toStringAsFixed(3)} RUSH to ${_shortenAddress(recipient)}.$tx';
  }

  Future<String> withdrawTokens({
    required String recipient,
    required double amountTokens,
  }) async {
    if (!_walletService.isConnected || _walletService.session == null) {
      return 'Connect wallet first.';
    }
    if (recipient.trim().isEmpty) {
      return 'Enter withdraw wallet address.';
    }
    final tokenUnits = (amountTokens * 1000).round();
    if (tokenUnits <= 0) {
      return 'Enter a valid amount (min 0.001 RUSH).';
    }
    if (tokenUnits > _stats.claimedSteps) {
      return 'Insufficient claimed RUSH balance.';
    }

    _isSubmittingTx = true;
    notifyListeners();
    final result = await _relayerService.sendTokenTransfer(
      fromAddress: _walletService.session!.address,
      toAddress: recipient.trim(),
      amountToken: amountTokens.toStringAsFixed(3),
      isWithdraw: true,
    );
    _isSubmittingTx = false;

    if (!result.success) {
      notifyListeners();
      return result.message;
    }

    final remaining = _stats.claimedSteps - tokenUnits;
    _stats = _stats.copyWith(claimedSteps: remaining);
    await _storageService.saveClaimedSteps(remaining);
    notifyListeners();
    final fee = result.estimatedBaseFee ?? _withdrawBaseFee;
    final tx = result.txHash == null
        ? ''
        : ' Tx: ${_shortenHash(result.txHash!)}';
    return 'Withdraw submitted. Base gas fee: $fee BASE.$tx';
  }

  Future<void> _onStepCount(StepCount event) async {
    _sensorReady = true;
    _latestSensorSteps = event.steps;

    if (!_stats.isTracking) {
      return;
    }

    if (_sessionStartSensorSteps == null) {
      _sessionStartSensorSteps = event.steps;
      return;
    }

    final sessionSensorDelta = event.steps - _sessionStartSensorSteps!;
    if (sessionSensorDelta < 0) {
      _sessionStartSensorSteps = event.steps;
      return;
    }

    final liveSessionSteps = _sessionAccumulatedSteps + sessionSensorDelta;
    final nextTotalSteps = _sessionStartTotalSteps + sessionSensorDelta;
    final deltaForDaily = nextTotalSteps - _stats.totalSteps;
    if (deltaForDaily <= 0) {
      return;
    }

    _stats = _stats.copyWith(
      totalSteps: nextTotalSteps,
      liveSessionSteps: liveSessionSteps,
    );
    _recordDailySteps(deltaForDaily, event.timeStamp);
    notifyListeners();
    _schedulePersist();
  }

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 650), () {
      unawaited(_persistStatsSnapshot());
    });
  }

  Future<void> _persistStatsSnapshot() async {
    if (_isPersisting) {
      _hasPendingPersist = true;
      return;
    }
    _isPersisting = true;
    do {
      _hasPendingPersist = false;
      final totalSnapshot = _stats.totalSteps;
      final dailySnapshot = Map<String, int>.from(_dailySteps);
      await Future.wait<void>([
        _storageService.saveTotalSteps(totalSnapshot),
        _storageService.saveDailySteps(dailySnapshot),
      ]);
    } while (_hasPendingPersist);
    _isPersisting = false;
  }

  void _recordDailySteps(int delta, DateTime timestamp) {
    final localTime = timestamp.toLocal();
    final key = _dateKey(localTime);
    _dailySteps[key] = (_dailySteps[key] ?? 0) + delta;
    _trimDailyHistory();
  }

  void _trimDailyHistory() {
    if (_dailySteps.isEmpty) {
      return;
    }

    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day - 29);
    _dailySteps.removeWhere((key, _) {
      final date = DateTime.tryParse(key);
      return date == null || date.isBefore(cutoff);
    });
  }

  String _dateKey(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().split('T').first;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _shortenAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.length < 12) return trimmed;
    return '${trimmed.substring(0, 6)}...${trimmed.substring(trimmed.length - 4)}';
  }

  String _shortenHash(String hash) {
    if (hash.length < 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 6)}';
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    unawaited(_persistStatsSnapshot());
    _stepSubscription?.cancel();
    _pedestrianSubscription?.cancel();
    super.dispose();
  }
}
