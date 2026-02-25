import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/web3_config.dart';
import '../controllers/walk_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/badge_tier.dart';
import '../models/walk_stats.dart';
import '../services/pedometer_service.dart';
import '../services/app_update_service.dart';
import '../services/relayer_service.dart';
import '../services/storage_service.dart';
import '../services/wallet_service.dart';
import '../widgets/animated_metric_text.dart';
import '../widgets/nebula_background.dart';
import '../widgets/status_pill.dart';
import '../widgets/weekly_steps_poles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userDisplayName,
    this.onSignOutPressed,
  });

  final String userDisplayName;
  final Future<void> Function()? onSignOutPressed;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final WalkController _controller;
  late final AnimationController _pulseController;
  late final AnimationController _entryController;
  late final Animation<double> _pulseScale;
  late final Animation<Offset> _walkSlide;
  final _storageService = StorageService();
  final _appUpdateService = AppUpdateService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _walkSlide =
        Tween<Offset>(
          begin: const Offset(0, 0.07),
          end: const Offset(0, -0.07),
        ).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
    _controller = WalkController(
      storageService: _storageService,
      pedometerService: PedometerService(),
      walletService: WalletService(),
      relayerService: RelayerService(),
    )..initialize();
    _controller.addListener(_syncPulseAnimation);
    _scheduleAutoUpdateCheck();
  }

  @override
  void dispose() {
    _controller.removeListener(_syncPulseAnimation);
    _controller.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _syncPulseAnimation() {
    final shouldAnimate = _controller.stats.isTracking;
    if (shouldAnimate && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!shouldAnimate && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _scheduleAutoUpdateCheck() {
    Future<void>.delayed(const Duration(seconds: 2), () async {
      if (!mounted) {
        return;
      }
      final message = await _appUpdateService.checkAndMaybeUpdate(
        userInitiated: false,
      );
      if (message != null) {
        _showMessage(message);
      }
    });
  }

  Future<void> _checkUpdatesManually() async {
    final message = await _appUpdateService.checkAndMaybeUpdate(
      userInitiated: true,
    );
    if (message != null) {
      _showMessage(message);
    }
  }

  Future<void> _showBackupDialog() async {
    final code = _controller.createBackupCode();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Backup Code'),
          content: SingleChildScrollView(
            child: SelectableText(
              code,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
                _showMessage('Backup code copied. Save it safely.');
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRestoreDialog() async {
    final backupController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restore Backup'),
          content: TextField(
            controller: backupController,
            maxLines: 6,
            decoration: const InputDecoration(hintText: 'Paste backup code'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final msg = await _controller.restoreFromBackupCode(
                  backupController.text,
                );
                if (!dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                _showMessage(msg);
              },
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleTracking() async {
    if (_controller.stats.isTracking) {
      await _controller.stopTracking();
      return;
    }

    final started = await _controller.startTracking();
    if (started) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> _claimTokens() async {
    final claimed = await _controller.claimAllTokens();
    if (claimed <= 0) {
      _showMessage('No claimable RUSH yet. Walk more to earn.');
      return;
    }
    await HapticFeedback.heavyImpact();
    _showMessage('Claimed ${claimed.toStringAsFixed(3)} RUSH');
  }

  Future<void> _openConnectWalletSheet() async {
    final addressController = TextEditingController(
      text: _controller.walletAddress ?? '',
    );
    var provider = WalletProviderType.walletConnect;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect Wallet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<WalletProviderType>(
                    initialValue: provider,
                    items: const [
                      DropdownMenuItem(
                        value: WalletProviderType.walletConnect,
                        child: Text('WalletConnect'),
                      ),
                      DropdownMenuItem(
                        value: WalletProviderType.privy,
                        child: Text('Privy'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setLocalState(() => provider = value);
                    },
                    decoration: const InputDecoration(labelText: 'Provider'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Wallet Address',
                      hintText: '0x...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final msg = await _controller.connectWallet(
                          provider: provider,
                          address: addressController.text.trim(),
                        );
                        if (!mounted) {
                          return;
                        }
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                        _showMessage(msg);
                      },
                      child: const Text('Connect'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openWithdrawSheet() async {
    final recipientController = TextEditingController();
    final amountController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Withdraw RUSH',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: recipientController,
                decoration: const InputDecoration(
                  labelText: 'Receiver Address',
                  hintText: '0x...',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount (RUSH)',
                  hintText: '10.5',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Withdraw uses Base gas fee (~${_controller.withdrawBaseFee} BASE).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0;
                    final msg = await _controller.withdrawTokens(
                      recipient: recipientController.text.trim(),
                      amountTokens: amount,
                    );
                    if (!mounted) {
                      return;
                    }
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                    _showMessage(msg);
                  },
                  child: const Text('Confirm Withdraw'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStagger({required int index, required Widget child}) {
    final start = (index * 0.08).clamp(0.0, 0.8);
    final end = (start + 0.25).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.14),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final stats = _controller.stats;
              final currentBadge = BadgeTier.fromSteps(stats.totalSteps);
              final nextBadge = BadgeTier.nextTier(stats.totalSteps);
              final progressToNext = nextBadge == null
                  ? 1.0
                  : (stats.totalSteps / nextBadge.minSteps).clamp(0.0, 1.0);

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                children: [
                  _buildStagger(index: 0, child: _buildHeader()),
                  const SizedBox(height: 14),
                  _buildStagger(
                    index: 1,
                    child: _buildTrackingHero(stats: stats),
                  ),
                  const SizedBox(height: 14),
                  _buildStagger(
                    index: 2,
                    child: _buildMetricGrid(stats: stats),
                  ),
                  const SizedBox(height: 12),
                  _buildStagger(
                    index: 3,
                    child: WeeklyStepsPoles(items: _controller.last7DaysSteps),
                  ),
                  const SizedBox(height: 12),
                  _buildStagger(
                    index: 4,
                    child: _buildBadgeProgress(
                      currentBadge: currentBadge,
                      nextBadge: nextBadge,
                      progressToNext: progressToNext,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStagger(
                    index: 5,
                    child: _buildRewardsCard(stats: stats),
                  ),
                  const SizedBox(height: 12),
                  _buildStagger(index: 6, child: _buildWalletCard()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'rush2earn',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 2),
              Text(
                'Professional walk-to-earn dashboard',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Hi, ${widget.userDisplayName}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.accent),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(
                    label: 'Tracking',
                    active: _controller.stats.isTracking,
                    activeLabel: 'Live',
                    inactiveLabel: 'Paused',
                  ),
                  StatusPill(
                    label: 'Wallet',
                    active: _controller.isWalletConnected,
                    activeLabel: 'Connected',
                    inactiveLabel: 'Offline',
                  ),
                  StatusPill(
                    label: 'Sensor',
                    active: _controller.sensorReady,
                    activeLabel: _formatPedestrianState(
                      _controller.pedestrianState,
                    ),
                    inactiveLabel: 'Waiting',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.onSignOutPressed != null)
          IconButton(
            onPressed: () async {
              await widget.onSignOutPressed!.call();
            },
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
          ),
      ],
    );
  }

  Widget _buildTrackingHero({required WalkStats stats}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_controller.error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _controller.error!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.amber),
                ),
              ),
            Center(
              child: GestureDetector(
                onTap: _controller.isLoading ? null : _toggleTracking,
                child: ScaleTransition(
                  scale: _pulseScale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    width: 215,
                    height: 215,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: stats.isTracking
                            ? const [AppTheme.primary, AppTheme.accent]
                            : const [Color(0xFF213149), Color(0xFF102235)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (stats.isTracking
                                      ? AppTheme.primary
                                      : AppTheme.accent)
                                  .withValues(alpha: 0.34),
                          blurRadius: stats.isTracking ? 36 : 18,
                          spreadRadius: stats.isTracking ? 4 : 1,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.1,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (stats.isTracking)
                            SlideTransition(
                              position: _walkSlide,
                              child: const Icon(
                                Icons.directions_walk_rounded,
                                size: 56,
                                color: Color(0xFF072014),
                              ),
                            )
                          else
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 58,
                              color: Colors.white,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            stats.isTracking ? 'TRACKING' : 'START WALK',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                  color: stats.isTracking
                                      ? const Color(0xFF072014)
                                      : Colors.white,
                                ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedMetricText(
                            value: stats.liveSessionSteps.toDouble(),
                            suffix: ' live steps',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: stats.isTracking
                                      ? const Color(
                                          0xFF072014,
                                        ).withValues(alpha: 0.82)
                                      : Colors.white70,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stats.isTracking
                                ? 'Tap to pause session'
                                : 'Tap to begin new session',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: stats.isTracking
                                      ? const Color(
                                          0xFF072014,
                                        ).withValues(alpha: 0.8)
                                      : AppTheme.textMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid({required WalkStats stats}) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetricCard(
          widthFactor: 0.5,
          label: 'Today Steps',
          icon: Icons.directions_walk_rounded,
          accent: AppTheme.primary,
          value: AnimatedMetricText(
            value: stats.totalSteps.toDouble(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
        ),
        _MetricCard(
          widthFactor: 0.5,
          label: 'Claimable',
          icon: Icons.savings_outlined,
          accent: AppTheme.accent,
          value: AnimatedMetricText(
            value: stats.claimableTokens,
            decimals: 3,
            suffix: ' RUSH',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 19),
          ),
        ),
        _MetricCard(
          widthFactor: 0.5,
          label: 'Claimed',
          icon: Icons.workspace_premium_rounded,
          accent: const Color(0xFFF4D37A),
          value: AnimatedMetricText(
            value: stats.claimedTokens,
            decimals: 3,
            suffix: ' RUSH',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 19),
          ),
        ),
        _MetricCard(
          widthFactor: 0.5,
          label: 'Network',
          icon: Icons.hub_outlined,
          accent: const Color(0xFFBDA7FF),
          value: Text(
            'Base #${Web3Config.baseMainnetChainId}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeProgress({
    required BadgeTier currentBadge,
    required BadgeTier? nextBadge,
    required double progressToNext,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Badge Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentBadge.color.withValues(alpha: 0.2),
                    boxShadow: [
                      BoxShadow(
                        color: currentBadge.glowColor.withValues(alpha: 0.45),
                        blurRadius: 14,
                      ),
                    ],
                    border: Border.all(
                      color: currentBadge.color.withValues(alpha: 0.75),
                    ),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: currentBadge.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentBadge.name} Badge',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: currentBadge.color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Unlocked at ${currentBadge.minSteps} steps',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progressToNext),
              duration: const Duration(milliseconds: 580),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(100),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(currentBadge.color),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              nextBadge == null
                  ? 'Max tier reached: Diamond'
                  : 'Next upgrade: ${nextBadge.name} at ${nextBadge.minSteps} steps',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsCard({required WalkStats stats}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rewards', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Earned: ${stats.earnedTokens.toStringAsFixed(3)} RUSH',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Claimable: ${stats.claimableTokens.toStringAsFixed(3)} RUSH',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Claimed: ${stats.claimedTokens.toStringAsFixed(3)} RUSH',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _controller.isSubmittingTx ? null : _claimTokens,
                    icon: _controller.isSubmittingTx
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.card_giftcard_rounded),
                    label: const Text('Claim'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _controller.isSubmittingTx
                        ? null
                        : _openWithdrawSheet,
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Withdraw'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Claim is free. Withdraw has Base network gas.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    final address = _controller.walletAddress;
    final provider = _controller.walletProvider;
    final providerLabel = provider == WalletProviderType.privy
        ? 'Privy'
        : 'WalletConnect';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Wallet & Chain',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusPill(
                  label: 'Tx',
                  active: !_controller.isSubmittingTx,
                  activeLabel: 'Ready',
                  inactiveLabel: 'Submitting',
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (address == null) ...[
              Text(
                'No wallet connected. Connect to use send/withdraw.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              Text(
                'Address: ${_shortAddress(address)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Provider: $providerLabel',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Token: ${_shortAddress(_controller.rushTokenContractAddress)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _controller.isWalletConnected
                        ? null
                        : () async {
                            await _openConnectWalletSheet();
                          },
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Connect'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: !_controller.isWalletConnected
                        ? null
                        : () async {
                            await _controller.disconnectWallet();
                            _showMessage('Wallet disconnected.');
                          },
                    icon: const Icon(Icons.link_off_rounded),
                    label: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _checkUpdatesManually,
                icon: const Icon(Icons.system_update_alt_rounded),
                label: const Text('Check For Updates'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showBackupDialog,
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Backup Data'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showRestoreDialog,
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restore Data'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.length < 14) return trimmed;
    return '${trimmed.substring(0, 8)}...${trimmed.substring(trimmed.length - 6)}';
  }

  String _formatPedestrianState(String state) {
    if (state.isEmpty) {
      return 'Unknown';
    }
    return state[0].toUpperCase() + state.substring(1).toLowerCase();
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.widthFactor,
    required this.label,
    required this.icon,
    required this.value,
    required this.accent,
  });

  final double widthFactor;
  final String label;
  final IconData icon;
  final Widget value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 46) * widthFactor - 5;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: accent.withValues(alpha: 0.18),
                      border: Border.all(color: accent.withValues(alpha: 0.33)),
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              value,
            ],
          ),
        ),
      ),
    );
  }
}
