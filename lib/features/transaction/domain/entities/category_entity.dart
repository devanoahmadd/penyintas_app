import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';

/// Entitas kategori — built-in maupun custom buatan user.
///
/// Label built-in di-resolve via [labelKey] + AppLocalizations di layer
/// presentasi. Custom kategori pakai [labelOverride] yang user isi sendiri.
class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.slug,
    this.labelKey,
    this.labelOverride,
    required this.isBuiltIn,
    required this.isLimitable,
    required this.type,
    required this.sortOrder,
    this.iconSlug,
  });

  final int id;

  /// Pengenal unik kategori (mis. 'food', 'transport').
  /// Dipakai sebagai FK di tabel lain.
  final String slug;

  /// Key l10n untuk label built-in (mis. 'category_food').
  /// null untuk custom kategori.
  final String? labelKey;

  /// Nama yang diisi user untuk custom kategori.
  /// null untuk built-in (gunakan [labelKey] via AppLocalizations).
  final String? labelOverride;

  final bool isBuiltIn;

  /// Apakah kategori ini bisa diberi batas anggaran (limit).
  final bool isLimitable;

  /// Tipe transaksi: 'expense' | 'income'.
  final String type;

  final int sortOrder;

  /// Slug ikon untuk custom kategori. null = built-in (gunakan CategoryMetadata).
  final String? iconSlug;

  bool get isExpense => type == 'expense';
  bool get isIncomeType => type == 'income';

  @override
  List<Object?> get props =>
      [id, slug, labelKey, labelOverride, isBuiltIn, isLimitable, type, sortOrder, iconSlug];

  CategoryEntity copyWith({
    int? id,
    String? slug,
    String? labelKey,
    String? labelOverride,
    bool? isBuiltIn,
    bool? isLimitable,
    String? type,
    int? sortOrder,
    Value<String?> iconSlug = const Value.absent(),
  }) => CategoryEntity(
    id: id ?? this.id,
    slug: slug ?? this.slug,
    labelKey: labelKey ?? this.labelKey,
    labelOverride: labelOverride ?? this.labelOverride,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    isLimitable: isLimitable ?? this.isLimitable,
    type: type ?? this.type,
    sortOrder: sortOrder ?? this.sortOrder,
    iconSlug: iconSlug.present ? iconSlug.value : this.iconSlug,
  );
}
