enum WalletProviderType { walletConnect, privy }

class WalletSession {
  const WalletSession({
    required this.provider,
    required this.address,
  });

  final WalletProviderType provider;
  final String address;
}

class WalletService {
  WalletSession? _session;
  WalletSession? get session => _session;

  bool get isConnected => _session != null;

  Future<WalletSession> connect({
    required WalletProviderType provider,
    required String address,
  }) async {
    final normalized = address.trim();
    if (!_isValidEvmAddress(normalized)) {
      throw const FormatException('Invalid EVM wallet address.');
    }

    // In production, this method should be replaced with true SDK connect flows:
    // - WalletConnect pairing/session
    // - Privy authentication/session
    _session = WalletSession(provider: provider, address: normalized);
    return _session!;
  }

  Future<void> disconnect() async {
    _session = null;
  }

  bool _isValidEvmAddress(String address) {
    final exp = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return exp.hasMatch(address);
  }
}
