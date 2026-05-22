import 'package:equatable/equatable.dart';

class CurrencyConfig extends Equatable {
  const CurrencyConfig({
    required this.code,
    required this.symbol,
    required this.locale,
    required this.decimalDigits,
    required this.compactThousand,
    required this.compactMillion,
  });

  final String code;
  final String symbol;
  final String locale;
  final int decimalDigits;
  final String compactThousand;
  final String compactMillion;

  // Hanya IDR di Phase 7 — full registry ditambahkan di Phase 8B
  static const idr = CurrencyConfig(
    code: 'IDR',
    symbol: 'Rp',
    locale: 'id_ID',
    decimalDigits: 0,
    compactThousand: 'rb',
    compactMillion: 'jt',
  );

  // Placeholder registry — akan di-expand di Phase 8B
  static const Map<String, CurrencyConfig> registry = {
    'IDR': idr,
  };

  static CurrencyConfig fromCode(String code) =>
      registry[code.toUpperCase()] ?? idr;

  @override
  List<Object> get props => [code, symbol, locale, decimalDigits, compactThousand, compactMillion];
}
