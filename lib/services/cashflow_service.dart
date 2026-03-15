import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class HighRiskParty {
  final String partyId;
  final String partyName;
  final String riskLevel;
  final String reason;

  HighRiskParty({
    required this.partyId,
    required this.partyName,
    required this.riskLevel,
    required this.reason,
  });

  factory HighRiskParty.fromMap(Map<String, dynamic> map) {
    return HighRiskParty(
      partyId: map['partyId'] ?? '',
      partyName: map['partyName'] ?? '',
      riskLevel: map['riskLevel'] ?? '',
      reason: map['reason'] ?? '',
    );
  }
}

class CashflowForecast {
  final double totalUpcomingReceivables;
  final double totalUpcomingPayables;
  final int coveragePercent;
  final Map<String, dynamic> dailyProjections;
  final List<HighRiskParty> highRiskParties;
  final String summaryMessage;

  CashflowForecast({
    required this.totalUpcomingReceivables,
    required this.totalUpcomingPayables,
    required this.coveragePercent,
    required this.dailyProjections,
    required this.highRiskParties,
    required this.summaryMessage,
  });

  factory CashflowForecast.fromMap(Map<String, dynamic> map) {
    return CashflowForecast(
      totalUpcomingReceivables: (map['totalUpcomingReceivables'] ?? 0)
          .toDouble(),
      totalUpcomingPayables: (map['totalUpcomingPayables'] ?? 0).toDouble(),
      coveragePercent: (map['coveragePercent'] ?? 0).toInt(),
      dailyProjections: Map<String, dynamic>.from(
        map['dailyProjections'] ?? {},
      ),
      highRiskParties: (map['highRiskParties'] as List? ?? [])
          .map((item) => HighRiskParty.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      summaryMessage: map['summaryMessage'] ?? '',
    );
  }

  factory CashflowForecast.empty() {
    return CashflowForecast(
      totalUpcomingReceivables: 0,
      totalUpcomingPayables: 0,
      coveragePercent: 100,
      dailyProjections: {},
      highRiskParties: [],
      summaryMessage: '',
    );
  }
}

final cashflowServiceProvider = Provider<CashflowService>((ref) {
  return CashflowService();
});

final cashflowForecastProvider = FutureProvider<CashflowForecast>((ref) async {
  final authState = ref.watch(authStateProvider);

  if (authState.isLoading || authState.value == null) {
    return CashflowForecast.empty();
  }

  final service = ref.watch(cashflowServiceProvider);
  return service.getForecast();
});

class CashflowService {
  Future<CashflowForecast> getForecast() async {
    try {
      final result = await FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('analyzeCashflow').call();

      return CashflowForecast.fromMap(Map<String, dynamic>.from(result.data));
    } catch (e) {
      throw Exception('Failed to get cashflow forecast: $e');
    }
  }
}
