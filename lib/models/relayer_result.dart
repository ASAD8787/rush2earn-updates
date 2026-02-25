class RelayerResult {
  const RelayerResult({
    required this.success,
    required this.message,
    this.txHash,
    this.estimatedBaseFee,
  });

  final bool success;
  final String message;
  final String? txHash;
  final double? estimatedBaseFee;
}
