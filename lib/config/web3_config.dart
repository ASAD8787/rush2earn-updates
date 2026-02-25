class Web3Config {
  static const int baseMainnetChainId = 8453;
  static const String networkDisplayName = 'Base Mainnet';
  static const String baseMainnetRpc = 'https://mainnet.base.org';
  static const String rushTokenContract =
      '0xa5c0EA1e447992F3Ed975507b544CD2D95b2f533';

  // Replace with your backend relayer endpoint.
  static const String relayerBaseUrl = 'https://your-relayer.example.com';

  // Public endpoint returning latest app version and APK URL.
  // Example response:
  // {"version":"1.0.1","apkUrl":"https://example.com/rush2earn-v101.apk","notes":"Bug fixes"}
  static const String appUpdateManifestUrl =
      'https://raw.githubusercontent.com/ASAD8787/rush2earn-updates/main/version.json';
}
