class WalkStats {
  const WalkStats({
    required this.totalSteps,
    required this.isTracking,
    required this.liveSessionSteps,
    required this.claimedSteps,
  });

  final int totalSteps;
  final bool isTracking;
  final int liveSessionSteps;
  final int claimedSteps;

  double get earnedTokens => totalSteps / 1000.0;
  int get claimableSteps => totalSteps > claimedSteps ? totalSteps - claimedSteps : 0;
  double get claimableTokens => claimableSteps / 1000.0;
  double get claimedTokens => claimedSteps / 1000.0;

  WalkStats copyWith({
    int? totalSteps,
    bool? isTracking,
    int? liveSessionSteps,
    int? claimedSteps,
  }) {
    return WalkStats(
      totalSteps: totalSteps ?? this.totalSteps,
      isTracking: isTracking ?? this.isTracking,
      liveSessionSteps: liveSessionSteps ?? this.liveSessionSteps,
      claimedSteps: claimedSteps ?? this.claimedSteps,
    );
  }
}
