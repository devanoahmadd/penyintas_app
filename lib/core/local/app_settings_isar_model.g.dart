// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_isar_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppSettingsIsarModelCollection on Isar {
  IsarCollection<AppSettingsIsarModel> get appSettingsIsarModels =>
      this.collection();
}

const AppSettingsIsarModelSchema = CollectionSchema(
  name: r'AppSettingsIsarModel',
  id: -142477573158583996,
  properties: {
    r'emergencyFundPct': PropertySchema(
      id: 0,
      name: r'emergencyFundPct',
      type: IsarType.double,
    ),
    r'fixedExpenses': PropertySchema(
      id: 1,
      name: r'fixedExpenses',
      type: IsarType.long,
    ),
    r'locale': PropertySchema(
      id: 2,
      name: r'locale',
      type: IsarType.string,
    ),
    r'monthlyIncome': PropertySchema(
      id: 3,
      name: r'monthlyIncome',
      type: IsarType.long,
    ),
    r'onboardingCompleted': PropertySchema(
      id: 4,
      name: r'onboardingCompleted',
      type: IsarType.bool,
    ),
    r'paymentDate': PropertySchema(
      id: 5,
      name: r'paymentDate',
      type: IsarType.long,
    ),
    r'themeMode': PropertySchema(
      id: 6,
      name: r'themeMode',
      type: IsarType.string,
    )
  },
  estimateSize: _appSettingsIsarModelEstimateSize,
  serialize: _appSettingsIsarModelSerialize,
  deserialize: _appSettingsIsarModelDeserialize,
  deserializeProp: _appSettingsIsarModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _appSettingsIsarModelGetId,
  getLinks: _appSettingsIsarModelGetLinks,
  attach: _appSettingsIsarModelAttach,
  version: '3.1.0+1',
);

int _appSettingsIsarModelEstimateSize(
  AppSettingsIsarModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.locale.length * 3;
  bytesCount += 3 + object.themeMode.length * 3;
  return bytesCount;
}

void _appSettingsIsarModelSerialize(
  AppSettingsIsarModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.emergencyFundPct);
  writer.writeLong(offsets[1], object.fixedExpenses);
  writer.writeString(offsets[2], object.locale);
  writer.writeLong(offsets[3], object.monthlyIncome);
  writer.writeBool(offsets[4], object.onboardingCompleted);
  writer.writeLong(offsets[5], object.paymentDate);
  writer.writeString(offsets[6], object.themeMode);
}

AppSettingsIsarModel _appSettingsIsarModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppSettingsIsarModel();
  object.emergencyFundPct = reader.readDouble(offsets[0]);
  object.fixedExpenses = reader.readLong(offsets[1]);
  object.id = id;
  object.locale = reader.readString(offsets[2]);
  object.monthlyIncome = reader.readLong(offsets[3]);
  object.onboardingCompleted = reader.readBool(offsets[4]);
  object.paymentDate = reader.readLong(offsets[5]);
  object.themeMode = reader.readString(offsets[6]);
  return object;
}

P _appSettingsIsarModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appSettingsIsarModelGetId(AppSettingsIsarModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appSettingsIsarModelGetLinks(
    AppSettingsIsarModel object) {
  return [];
}

void _appSettingsIsarModelAttach(
    IsarCollection<dynamic> col, Id id, AppSettingsIsarModel object) {
  object.id = id;
}

extension AppSettingsIsarModelQueryWhereSort
    on QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QWhere> {
  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppSettingsIsarModelQueryWhere
    on QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QWhereClause> {
  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AppSettingsIsarModelQueryFilter on QueryBuilder<AppSettingsIsarModel,
    AppSettingsIsarModel, QFilterCondition> {
  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> emergencyFundPctEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emergencyFundPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> emergencyFundPctGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'emergencyFundPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> emergencyFundPctLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'emergencyFundPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> emergencyFundPctBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'emergencyFundPct',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> fixedExpensesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fixedExpenses',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> fixedExpensesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fixedExpenses',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> fixedExpensesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fixedExpenses',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> fixedExpensesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fixedExpenses',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> localeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'locale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> localeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'locale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> localeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'locale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> localeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'locale',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> localeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'locale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> localeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'locale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
          QAfterFilterCondition>
      localeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'locale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
          QAfterFilterCondition>
      localeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'locale',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> localeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'locale',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> localeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'locale',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> monthlyIncomeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthlyIncome',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> monthlyIncomeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'monthlyIncome',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> monthlyIncomeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'monthlyIncome',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> monthlyIncomeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'monthlyIncome',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> onboardingCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onboardingCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> paymentDateEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentDate',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> paymentDateGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentDate',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> paymentDateLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentDate',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> paymentDateBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> themeModeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'themeMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> themeModeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'themeMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> themeModeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'themeMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> themeModeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'themeMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> themeModeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'themeMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> themeModeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'themeMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
          QAfterFilterCondition>
      themeModeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'themeMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
          QAfterFilterCondition>
      themeModeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'themeMode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> themeModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'themeMode',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel,
      QAfterFilterCondition> themeModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'themeMode',
        value: '',
      ));
    });
  }
}

extension AppSettingsIsarModelQueryObject on QueryBuilder<AppSettingsIsarModel,
    AppSettingsIsarModel, QFilterCondition> {}

extension AppSettingsIsarModelQueryLinks on QueryBuilder<AppSettingsIsarModel,
    AppSettingsIsarModel, QFilterCondition> {}

extension AppSettingsIsarModelQuerySortBy
    on QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QSortBy> {
  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByEmergencyFundPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emergencyFundPct', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByEmergencyFundPctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emergencyFundPct', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByFixedExpenses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedExpenses', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByFixedExpensesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedExpenses', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByLocale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByLocaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByMonthlyIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyIncome', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByMonthlyIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyIncome', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByOnboardingCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onboardingCompleted', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByOnboardingCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onboardingCompleted', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDate', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByPaymentDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDate', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      sortByThemeModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.desc);
    });
  }
}

extension AppSettingsIsarModelQuerySortThenBy
    on QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QSortThenBy> {
  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByEmergencyFundPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emergencyFundPct', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByEmergencyFundPctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emergencyFundPct', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByFixedExpenses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedExpenses', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByFixedExpensesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedExpenses', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByLocale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByLocaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByMonthlyIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyIncome', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByMonthlyIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyIncome', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByOnboardingCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onboardingCompleted', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByOnboardingCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onboardingCompleted', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDate', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByPaymentDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDate', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QAfterSortBy>
      thenByThemeModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.desc);
    });
  }
}

extension AppSettingsIsarModelQueryWhereDistinct
    on QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QDistinct> {
  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QDistinct>
      distinctByEmergencyFundPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'emergencyFundPct');
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QDistinct>
      distinctByFixedExpenses() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fixedExpenses');
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QDistinct>
      distinctByLocale({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'locale', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QDistinct>
      distinctByMonthlyIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'monthlyIncome');
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QDistinct>
      distinctByOnboardingCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onboardingCompleted');
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QDistinct>
      distinctByPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentDate');
    });
  }

  QueryBuilder<AppSettingsIsarModel, AppSettingsIsarModel, QDistinct>
      distinctByThemeMode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'themeMode', caseSensitive: caseSensitive);
    });
  }
}

extension AppSettingsIsarModelQueryProperty on QueryBuilder<
    AppSettingsIsarModel, AppSettingsIsarModel, QQueryProperty> {
  QueryBuilder<AppSettingsIsarModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppSettingsIsarModel, double, QQueryOperations>
      emergencyFundPctProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'emergencyFundPct');
    });
  }

  QueryBuilder<AppSettingsIsarModel, int, QQueryOperations>
      fixedExpensesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fixedExpenses');
    });
  }

  QueryBuilder<AppSettingsIsarModel, String, QQueryOperations>
      localeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'locale');
    });
  }

  QueryBuilder<AppSettingsIsarModel, int, QQueryOperations>
      monthlyIncomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'monthlyIncome');
    });
  }

  QueryBuilder<AppSettingsIsarModel, bool, QQueryOperations>
      onboardingCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onboardingCompleted');
    });
  }

  QueryBuilder<AppSettingsIsarModel, int, QQueryOperations>
      paymentDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentDate');
    });
  }

  QueryBuilder<AppSettingsIsarModel, String, QQueryOperations>
      themeModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'themeMode');
    });
  }
}
