class OcrResult {
  final String? partyName;
  final String? invoiceNumber;
  final DateTime? invoiceDate;
  final double? amount;
  final String? confidenceScore;

  OcrResult({
    this.partyName,
    this.invoiceNumber,
    this.invoiceDate,
    this.amount,
    this.confidenceScore,
  });

  factory OcrResult.fromMap(Map<String, dynamic> map) {
    return OcrResult(
      partyName: map['partyName'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
      invoiceDate: map['invoiceDate'] != null 
          ? DateTime.tryParse(map['invoiceDate'] as String) 
          : null,
      amount: (map['amount'] ?? 0).toDouble(),
      confidenceScore: map['confidenceScore'] as String?,
    );
  }

  bool get isEmpty => 
      partyName == null && 
      invoiceNumber == null && 
      invoiceDate == null && 
      (amount == null || amount == 0);
}
