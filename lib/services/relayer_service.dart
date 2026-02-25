import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/web3_config.dart';
import '../models/relayer_result.dart';

class RelayerService {
  Future<RelayerResult> sendTokenTransfer({
    required String fromAddress,
    required String toAddress,
    required String amountToken,
    required bool isWithdraw,
  }) async {
    if (Web3Config.useMockRelayerForTesting) {
      final now = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
      return RelayerResult(
        success: true,
        message: isWithdraw
            ? 'Mock withdraw submitted successfully.'
            : 'Mock send submitted successfully.',
        txHash: '0xmock$now',
        estimatedBaseFee: 0.00012,
      );
    }

    final uri = Uri.parse('${Web3Config.relayerBaseUrl}/v1/token/transfer');
    final payload = <String, dynamic>{
      'action': isWithdraw ? 'withdraw' : 'send',
      'chainId': Web3Config.baseMainnetChainId,
      'tokenAddress': Web3Config.rushTokenContract,
      'from': fromAddress,
      'to': toAddress,
      'amount': amountToken,
    };

    try {
      final res = await http.post(
        uri,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return RelayerResult(
          success: false,
          message: 'Relayer failed (${res.statusCode}).',
        );
      }

      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) {
        return const RelayerResult(
          success: false,
          message: 'Invalid relayer response.',
        );
      }

      return RelayerResult(
        success: body['success'] == true,
        message: (body['message'] ?? 'Submitted').toString(),
        txHash: body['txHash']?.toString(),
        estimatedBaseFee: (body['estimatedBaseFee'] as num?)?.toDouble(),
      );
    } catch (_) {
      return const RelayerResult(
        success: false,
        message: 'Relayer is unreachable. Configure backend endpoint first.',
      );
    }
  }
}
