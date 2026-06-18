// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('id'),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _monthlyIncomeMeta = const VerificationMeta(
    'monthlyIncome',
  );
  @override
  late final GeneratedColumn<int> monthlyIncome = GeneratedColumn<int>(
    'monthly_income',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paymentDateMeta = const VerificationMeta(
    'paymentDate',
  );
  @override
  late final GeneratedColumn<int> paymentDate = GeneratedColumn<int>(
    'payment_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _fixedExpensesMeta = const VerificationMeta(
    'fixedExpenses',
  );
  @override
  late final GeneratedColumn<int> fixedExpenses = GeneratedColumn<int>(
    'fixed_expenses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _emergencyFundPctMeta = const VerificationMeta(
    'emergencyFundPct',
  );
  @override
  late final GeneratedColumn<double> emergencyFundPct = GeneratedColumn<double>(
    'emergency_fund_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.10),
  );
  static const VerificationMeta _onboardingCreatedAtMeta =
      const VerificationMeta('onboardingCreatedAt');
  @override
  late final GeneratedColumn<DateTime> onboardingCreatedAt =
      GeneratedColumn<DateTime>(
        'onboarding_created_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reminderEnabledMeta = const VerificationMeta(
    'reminderEnabled',
  );
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
    'reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _reminderHourMeta = const VerificationMeta(
    'reminderHour',
  );
  @override
  late final GeneratedColumn<int> reminderHour = GeneratedColumn<int>(
    'reminder_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _reminderMinuteMeta = const VerificationMeta(
    'reminderMinute',
  );
  @override
  late final GeneratedColumn<int> reminderMinute = GeneratedColumn<int>(
    'reminder_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rentExpenseMeta = const VerificationMeta(
    'rentExpense',
  );
  @override
  late final GeneratedColumn<int> rentExpense = GeneratedColumn<int>(
    'rent_expense',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _utilitiesExpenseMeta = const VerificationMeta(
    'utilitiesExpense',
  );
  @override
  late final GeneratedColumn<int> utilitiesExpense = GeneratedColumn<int>(
    'utilities_expense',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _internetExpenseMeta = const VerificationMeta(
    'internetExpense',
  );
  @override
  late final GeneratedColumn<int> internetExpense = GeneratedColumn<int>(
    'internet_expense',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _phoneExpenseMeta = const VerificationMeta(
    'phoneExpense',
  );
  @override
  late final GeneratedColumn<int> phoneExpense = GeneratedColumn<int>(
    'phone_expense',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _otherFixedExpenseMeta = const VerificationMeta(
    'otherFixedExpense',
  );
  @override
  late final GeneratedColumn<int> otherFixedExpense = GeneratedColumn<int>(
    'other_fixed_expense',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _survivalModeActivatedAtMeta =
      const VerificationMeta('survivalModeActivatedAt');
  @override
  late final GeneratedColumn<DateTime> survivalModeActivatedAt =
      GeneratedColumn<DateTime>(
        'survival_mode_activated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _partialOnboardingStepMeta =
      const VerificationMeta('partialOnboardingStep');
  @override
  late final GeneratedColumn<int> partialOnboardingStep = GeneratedColumn<int>(
    'partial_onboarding_step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partialOnboardingAtMeta =
      const VerificationMeta('partialOnboardingAt');
  @override
  late final GeneratedColumn<int> partialOnboardingAt = GeneratedColumn<int>(
    'partial_onboarding_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    locale,
    themeMode,
    onboardingCompleted,
    monthlyIncome,
    paymentDate,
    fixedExpenses,
    emergencyFundPct,
    onboardingCreatedAt,
    reminderEnabled,
    reminderHour,
    reminderMinute,
    rentExpense,
    utilitiesExpense,
    internetExpense,
    phoneExpense,
    otherFixedExpense,
    survivalModeActivatedAt,
    partialOnboardingStep,
    partialOnboardingAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    }
    if (data.containsKey('monthly_income')) {
      context.handle(
        _monthlyIncomeMeta,
        monthlyIncome.isAcceptableOrUnknown(
          data['monthly_income']!,
          _monthlyIncomeMeta,
        ),
      );
    }
    if (data.containsKey('payment_date')) {
      context.handle(
        _paymentDateMeta,
        paymentDate.isAcceptableOrUnknown(
          data['payment_date']!,
          _paymentDateMeta,
        ),
      );
    }
    if (data.containsKey('fixed_expenses')) {
      context.handle(
        _fixedExpensesMeta,
        fixedExpenses.isAcceptableOrUnknown(
          data['fixed_expenses']!,
          _fixedExpensesMeta,
        ),
      );
    }
    if (data.containsKey('emergency_fund_pct')) {
      context.handle(
        _emergencyFundPctMeta,
        emergencyFundPct.isAcceptableOrUnknown(
          data['emergency_fund_pct']!,
          _emergencyFundPctMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_created_at')) {
      context.handle(
        _onboardingCreatedAtMeta,
        onboardingCreatedAt.isAcceptableOrUnknown(
          data['onboarding_created_at']!,
          _onboardingCreatedAtMeta,
        ),
      );
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
        _reminderEnabledMeta,
        reminderEnabled.isAcceptableOrUnknown(
          data['reminder_enabled']!,
          _reminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_hour')) {
      context.handle(
        _reminderHourMeta,
        reminderHour.isAcceptableOrUnknown(
          data['reminder_hour']!,
          _reminderHourMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minute')) {
      context.handle(
        _reminderMinuteMeta,
        reminderMinute.isAcceptableOrUnknown(
          data['reminder_minute']!,
          _reminderMinuteMeta,
        ),
      );
    }
    if (data.containsKey('rent_expense')) {
      context.handle(
        _rentExpenseMeta,
        rentExpense.isAcceptableOrUnknown(
          data['rent_expense']!,
          _rentExpenseMeta,
        ),
      );
    }
    if (data.containsKey('utilities_expense')) {
      context.handle(
        _utilitiesExpenseMeta,
        utilitiesExpense.isAcceptableOrUnknown(
          data['utilities_expense']!,
          _utilitiesExpenseMeta,
        ),
      );
    }
    if (data.containsKey('internet_expense')) {
      context.handle(
        _internetExpenseMeta,
        internetExpense.isAcceptableOrUnknown(
          data['internet_expense']!,
          _internetExpenseMeta,
        ),
      );
    }
    if (data.containsKey('phone_expense')) {
      context.handle(
        _phoneExpenseMeta,
        phoneExpense.isAcceptableOrUnknown(
          data['phone_expense']!,
          _phoneExpenseMeta,
        ),
      );
    }
    if (data.containsKey('other_fixed_expense')) {
      context.handle(
        _otherFixedExpenseMeta,
        otherFixedExpense.isAcceptableOrUnknown(
          data['other_fixed_expense']!,
          _otherFixedExpenseMeta,
        ),
      );
    }
    if (data.containsKey('survival_mode_activated_at')) {
      context.handle(
        _survivalModeActivatedAtMeta,
        survivalModeActivatedAt.isAcceptableOrUnknown(
          data['survival_mode_activated_at']!,
          _survivalModeActivatedAtMeta,
        ),
      );
    }
    if (data.containsKey('partial_onboarding_step')) {
      context.handle(
        _partialOnboardingStepMeta,
        partialOnboardingStep.isAcceptableOrUnknown(
          data['partial_onboarding_step']!,
          _partialOnboardingStepMeta,
        ),
      );
    }
    if (data.containsKey('partial_onboarding_at')) {
      context.handle(
        _partialOnboardingAtMeta,
        partialOnboardingAt.isAcceptableOrUnknown(
          data['partial_onboarding_at']!,
          _partialOnboardingAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
      )!,
      monthlyIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monthly_income'],
      )!,
      paymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_date'],
      )!,
      fixedExpenses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_expenses'],
      )!,
      emergencyFundPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}emergency_fund_pct'],
      )!,
      onboardingCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}onboarding_created_at'],
      ),
      reminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_enabled'],
      )!,
      reminderHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_hour'],
      )!,
      reminderMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minute'],
      )!,
      rentExpense: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rent_expense'],
      )!,
      utilitiesExpense: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}utilities_expense'],
      )!,
      internetExpense: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}internet_expense'],
      )!,
      phoneExpense: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phone_expense'],
      )!,
      otherFixedExpense: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}other_fixed_expense'],
      )!,
      survivalModeActivatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}survival_mode_activated_at'],
      ),
      partialOnboardingStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}partial_onboarding_step'],
      ),
      partialOnboardingAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}partial_onboarding_at'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String locale;
  final String themeMode;
  final bool onboardingCompleted;
  final int monthlyIncome;
  final int paymentDate;
  final int fixedExpenses;
  final double emergencyFundPct;
  final DateTime? onboardingCreatedAt;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int rentExpense;
  final int utilitiesExpense;
  final int internetExpense;
  final int phoneExpense;
  final int otherFixedExpense;
  final DateTime? survivalModeActivatedAt;
  final int? partialOnboardingStep;
  final int? partialOnboardingAt;
  const AppSetting({
    required this.id,
    required this.locale,
    required this.themeMode,
    required this.onboardingCompleted,
    required this.monthlyIncome,
    required this.paymentDate,
    required this.fixedExpenses,
    required this.emergencyFundPct,
    this.onboardingCreatedAt,
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.rentExpense,
    required this.utilitiesExpense,
    required this.internetExpense,
    required this.phoneExpense,
    required this.otherFixedExpense,
    this.survivalModeActivatedAt,
    this.partialOnboardingStep,
    this.partialOnboardingAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['locale'] = Variable<String>(locale);
    map['theme_mode'] = Variable<String>(themeMode);
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    map['monthly_income'] = Variable<int>(monthlyIncome);
    map['payment_date'] = Variable<int>(paymentDate);
    map['fixed_expenses'] = Variable<int>(fixedExpenses);
    map['emergency_fund_pct'] = Variable<double>(emergencyFundPct);
    if (!nullToAbsent || onboardingCreatedAt != null) {
      map['onboarding_created_at'] = Variable<DateTime>(onboardingCreatedAt);
    }
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    map['reminder_hour'] = Variable<int>(reminderHour);
    map['reminder_minute'] = Variable<int>(reminderMinute);
    map['rent_expense'] = Variable<int>(rentExpense);
    map['utilities_expense'] = Variable<int>(utilitiesExpense);
    map['internet_expense'] = Variable<int>(internetExpense);
    map['phone_expense'] = Variable<int>(phoneExpense);
    map['other_fixed_expense'] = Variable<int>(otherFixedExpense);
    if (!nullToAbsent || survivalModeActivatedAt != null) {
      map['survival_mode_activated_at'] = Variable<DateTime>(
        survivalModeActivatedAt,
      );
    }
    if (!nullToAbsent || partialOnboardingStep != null) {
      map['partial_onboarding_step'] = Variable<int>(partialOnboardingStep);
    }
    if (!nullToAbsent || partialOnboardingAt != null) {
      map['partial_onboarding_at'] = Variable<int>(partialOnboardingAt);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      locale: Value(locale),
      themeMode: Value(themeMode),
      onboardingCompleted: Value(onboardingCompleted),
      monthlyIncome: Value(monthlyIncome),
      paymentDate: Value(paymentDate),
      fixedExpenses: Value(fixedExpenses),
      emergencyFundPct: Value(emergencyFundPct),
      onboardingCreatedAt: onboardingCreatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(onboardingCreatedAt),
      reminderEnabled: Value(reminderEnabled),
      reminderHour: Value(reminderHour),
      reminderMinute: Value(reminderMinute),
      rentExpense: Value(rentExpense),
      utilitiesExpense: Value(utilitiesExpense),
      internetExpense: Value(internetExpense),
      phoneExpense: Value(phoneExpense),
      otherFixedExpense: Value(otherFixedExpense),
      survivalModeActivatedAt: survivalModeActivatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(survivalModeActivatedAt),
      partialOnboardingStep: partialOnboardingStep == null && nullToAbsent
          ? const Value.absent()
          : Value(partialOnboardingStep),
      partialOnboardingAt: partialOnboardingAt == null && nullToAbsent
          ? const Value.absent()
          : Value(partialOnboardingAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      locale: serializer.fromJson<String>(json['locale']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
      monthlyIncome: serializer.fromJson<int>(json['monthlyIncome']),
      paymentDate: serializer.fromJson<int>(json['paymentDate']),
      fixedExpenses: serializer.fromJson<int>(json['fixedExpenses']),
      emergencyFundPct: serializer.fromJson<double>(json['emergencyFundPct']),
      onboardingCreatedAt: serializer.fromJson<DateTime?>(
        json['onboardingCreatedAt'],
      ),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      reminderHour: serializer.fromJson<int>(json['reminderHour']),
      reminderMinute: serializer.fromJson<int>(json['reminderMinute']),
      rentExpense: serializer.fromJson<int>(json['rentExpense']),
      utilitiesExpense: serializer.fromJson<int>(json['utilitiesExpense']),
      internetExpense: serializer.fromJson<int>(json['internetExpense']),
      phoneExpense: serializer.fromJson<int>(json['phoneExpense']),
      otherFixedExpense: serializer.fromJson<int>(json['otherFixedExpense']),
      survivalModeActivatedAt: serializer.fromJson<DateTime?>(
        json['survivalModeActivatedAt'],
      ),
      partialOnboardingStep: serializer.fromJson<int?>(
        json['partialOnboardingStep'],
      ),
      partialOnboardingAt: serializer.fromJson<int?>(
        json['partialOnboardingAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'locale': serializer.toJson<String>(locale),
      'themeMode': serializer.toJson<String>(themeMode),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'monthlyIncome': serializer.toJson<int>(monthlyIncome),
      'paymentDate': serializer.toJson<int>(paymentDate),
      'fixedExpenses': serializer.toJson<int>(fixedExpenses),
      'emergencyFundPct': serializer.toJson<double>(emergencyFundPct),
      'onboardingCreatedAt': serializer.toJson<DateTime?>(onboardingCreatedAt),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'reminderHour': serializer.toJson<int>(reminderHour),
      'reminderMinute': serializer.toJson<int>(reminderMinute),
      'rentExpense': serializer.toJson<int>(rentExpense),
      'utilitiesExpense': serializer.toJson<int>(utilitiesExpense),
      'internetExpense': serializer.toJson<int>(internetExpense),
      'phoneExpense': serializer.toJson<int>(phoneExpense),
      'otherFixedExpense': serializer.toJson<int>(otherFixedExpense),
      'survivalModeActivatedAt': serializer.toJson<DateTime?>(
        survivalModeActivatedAt,
      ),
      'partialOnboardingStep': serializer.toJson<int?>(partialOnboardingStep),
      'partialOnboardingAt': serializer.toJson<int?>(partialOnboardingAt),
    };
  }

  AppSetting copyWith({
    int? id,
    String? locale,
    String? themeMode,
    bool? onboardingCompleted,
    int? monthlyIncome,
    int? paymentDate,
    int? fixedExpenses,
    double? emergencyFundPct,
    Value<DateTime?> onboardingCreatedAt = const Value.absent(),
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    int? rentExpense,
    int? utilitiesExpense,
    int? internetExpense,
    int? phoneExpense,
    int? otherFixedExpense,
    Value<DateTime?> survivalModeActivatedAt = const Value.absent(),
    Value<int?> partialOnboardingStep = const Value.absent(),
    Value<int?> partialOnboardingAt = const Value.absent(),
  }) => AppSetting(
    id: id ?? this.id,
    locale: locale ?? this.locale,
    themeMode: themeMode ?? this.themeMode,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    monthlyIncome: monthlyIncome ?? this.monthlyIncome,
    paymentDate: paymentDate ?? this.paymentDate,
    fixedExpenses: fixedExpenses ?? this.fixedExpenses,
    emergencyFundPct: emergencyFundPct ?? this.emergencyFundPct,
    onboardingCreatedAt: onboardingCreatedAt.present
        ? onboardingCreatedAt.value
        : this.onboardingCreatedAt,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    rentExpense: rentExpense ?? this.rentExpense,
    utilitiesExpense: utilitiesExpense ?? this.utilitiesExpense,
    internetExpense: internetExpense ?? this.internetExpense,
    phoneExpense: phoneExpense ?? this.phoneExpense,
    otherFixedExpense: otherFixedExpense ?? this.otherFixedExpense,
    survivalModeActivatedAt: survivalModeActivatedAt.present
        ? survivalModeActivatedAt.value
        : this.survivalModeActivatedAt,
    partialOnboardingStep: partialOnboardingStep.present
        ? partialOnboardingStep.value
        : this.partialOnboardingStep,
    partialOnboardingAt: partialOnboardingAt.present
        ? partialOnboardingAt.value
        : this.partialOnboardingAt,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      locale: data.locale.present ? data.locale.value : this.locale,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      monthlyIncome: data.monthlyIncome.present
          ? data.monthlyIncome.value
          : this.monthlyIncome,
      paymentDate: data.paymentDate.present
          ? data.paymentDate.value
          : this.paymentDate,
      fixedExpenses: data.fixedExpenses.present
          ? data.fixedExpenses.value
          : this.fixedExpenses,
      emergencyFundPct: data.emergencyFundPct.present
          ? data.emergencyFundPct.value
          : this.emergencyFundPct,
      onboardingCreatedAt: data.onboardingCreatedAt.present
          ? data.onboardingCreatedAt.value
          : this.onboardingCreatedAt,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      reminderHour: data.reminderHour.present
          ? data.reminderHour.value
          : this.reminderHour,
      reminderMinute: data.reminderMinute.present
          ? data.reminderMinute.value
          : this.reminderMinute,
      rentExpense: data.rentExpense.present
          ? data.rentExpense.value
          : this.rentExpense,
      utilitiesExpense: data.utilitiesExpense.present
          ? data.utilitiesExpense.value
          : this.utilitiesExpense,
      internetExpense: data.internetExpense.present
          ? data.internetExpense.value
          : this.internetExpense,
      phoneExpense: data.phoneExpense.present
          ? data.phoneExpense.value
          : this.phoneExpense,
      otherFixedExpense: data.otherFixedExpense.present
          ? data.otherFixedExpense.value
          : this.otherFixedExpense,
      survivalModeActivatedAt: data.survivalModeActivatedAt.present
          ? data.survivalModeActivatedAt.value
          : this.survivalModeActivatedAt,
      partialOnboardingStep: data.partialOnboardingStep.present
          ? data.partialOnboardingStep.value
          : this.partialOnboardingStep,
      partialOnboardingAt: data.partialOnboardingAt.present
          ? data.partialOnboardingAt.value
          : this.partialOnboardingAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('locale: $locale, ')
          ..write('themeMode: $themeMode, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('monthlyIncome: $monthlyIncome, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('fixedExpenses: $fixedExpenses, ')
          ..write('emergencyFundPct: $emergencyFundPct, ')
          ..write('onboardingCreatedAt: $onboardingCreatedAt, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('rentExpense: $rentExpense, ')
          ..write('utilitiesExpense: $utilitiesExpense, ')
          ..write('internetExpense: $internetExpense, ')
          ..write('phoneExpense: $phoneExpense, ')
          ..write('otherFixedExpense: $otherFixedExpense, ')
          ..write('survivalModeActivatedAt: $survivalModeActivatedAt, ')
          ..write('partialOnboardingStep: $partialOnboardingStep, ')
          ..write('partialOnboardingAt: $partialOnboardingAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    locale,
    themeMode,
    onboardingCompleted,
    monthlyIncome,
    paymentDate,
    fixedExpenses,
    emergencyFundPct,
    onboardingCreatedAt,
    reminderEnabled,
    reminderHour,
    reminderMinute,
    rentExpense,
    utilitiesExpense,
    internetExpense,
    phoneExpense,
    otherFixedExpense,
    survivalModeActivatedAt,
    partialOnboardingStep,
    partialOnboardingAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.locale == this.locale &&
          other.themeMode == this.themeMode &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.monthlyIncome == this.monthlyIncome &&
          other.paymentDate == this.paymentDate &&
          other.fixedExpenses == this.fixedExpenses &&
          other.emergencyFundPct == this.emergencyFundPct &&
          other.onboardingCreatedAt == this.onboardingCreatedAt &&
          other.reminderEnabled == this.reminderEnabled &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.rentExpense == this.rentExpense &&
          other.utilitiesExpense == this.utilitiesExpense &&
          other.internetExpense == this.internetExpense &&
          other.phoneExpense == this.phoneExpense &&
          other.otherFixedExpense == this.otherFixedExpense &&
          other.survivalModeActivatedAt == this.survivalModeActivatedAt &&
          other.partialOnboardingStep == this.partialOnboardingStep &&
          other.partialOnboardingAt == this.partialOnboardingAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> locale;
  final Value<String> themeMode;
  final Value<bool> onboardingCompleted;
  final Value<int> monthlyIncome;
  final Value<int> paymentDate;
  final Value<int> fixedExpenses;
  final Value<double> emergencyFundPct;
  final Value<DateTime?> onboardingCreatedAt;
  final Value<bool> reminderEnabled;
  final Value<int> reminderHour;
  final Value<int> reminderMinute;
  final Value<int> rentExpense;
  final Value<int> utilitiesExpense;
  final Value<int> internetExpense;
  final Value<int> phoneExpense;
  final Value<int> otherFixedExpense;
  final Value<DateTime?> survivalModeActivatedAt;
  final Value<int?> partialOnboardingStep;
  final Value<int?> partialOnboardingAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.locale = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.monthlyIncome = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.fixedExpenses = const Value.absent(),
    this.emergencyFundPct = const Value.absent(),
    this.onboardingCreatedAt = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.rentExpense = const Value.absent(),
    this.utilitiesExpense = const Value.absent(),
    this.internetExpense = const Value.absent(),
    this.phoneExpense = const Value.absent(),
    this.otherFixedExpense = const Value.absent(),
    this.survivalModeActivatedAt = const Value.absent(),
    this.partialOnboardingStep = const Value.absent(),
    this.partialOnboardingAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.locale = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.monthlyIncome = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.fixedExpenses = const Value.absent(),
    this.emergencyFundPct = const Value.absent(),
    this.onboardingCreatedAt = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.rentExpense = const Value.absent(),
    this.utilitiesExpense = const Value.absent(),
    this.internetExpense = const Value.absent(),
    this.phoneExpense = const Value.absent(),
    this.otherFixedExpense = const Value.absent(),
    this.survivalModeActivatedAt = const Value.absent(),
    this.partialOnboardingStep = const Value.absent(),
    this.partialOnboardingAt = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? locale,
    Expression<String>? themeMode,
    Expression<bool>? onboardingCompleted,
    Expression<int>? monthlyIncome,
    Expression<int>? paymentDate,
    Expression<int>? fixedExpenses,
    Expression<double>? emergencyFundPct,
    Expression<DateTime>? onboardingCreatedAt,
    Expression<bool>? reminderEnabled,
    Expression<int>? reminderHour,
    Expression<int>? reminderMinute,
    Expression<int>? rentExpense,
    Expression<int>? utilitiesExpense,
    Expression<int>? internetExpense,
    Expression<int>? phoneExpense,
    Expression<int>? otherFixedExpense,
    Expression<DateTime>? survivalModeActivatedAt,
    Expression<int>? partialOnboardingStep,
    Expression<int>? partialOnboardingAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (locale != null) 'locale': locale,
      if (themeMode != null) 'theme_mode': themeMode,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (monthlyIncome != null) 'monthly_income': monthlyIncome,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (fixedExpenses != null) 'fixed_expenses': fixedExpenses,
      if (emergencyFundPct != null) 'emergency_fund_pct': emergencyFundPct,
      if (onboardingCreatedAt != null)
        'onboarding_created_at': onboardingCreatedAt,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (reminderHour != null) 'reminder_hour': reminderHour,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (rentExpense != null) 'rent_expense': rentExpense,
      if (utilitiesExpense != null) 'utilities_expense': utilitiesExpense,
      if (internetExpense != null) 'internet_expense': internetExpense,
      if (phoneExpense != null) 'phone_expense': phoneExpense,
      if (otherFixedExpense != null) 'other_fixed_expense': otherFixedExpense,
      if (survivalModeActivatedAt != null)
        'survival_mode_activated_at': survivalModeActivatedAt,
      if (partialOnboardingStep != null)
        'partial_onboarding_step': partialOnboardingStep,
      if (partialOnboardingAt != null)
        'partial_onboarding_at': partialOnboardingAt,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? locale,
    Value<String>? themeMode,
    Value<bool>? onboardingCompleted,
    Value<int>? monthlyIncome,
    Value<int>? paymentDate,
    Value<int>? fixedExpenses,
    Value<double>? emergencyFundPct,
    Value<DateTime?>? onboardingCreatedAt,
    Value<bool>? reminderEnabled,
    Value<int>? reminderHour,
    Value<int>? reminderMinute,
    Value<int>? rentExpense,
    Value<int>? utilitiesExpense,
    Value<int>? internetExpense,
    Value<int>? phoneExpense,
    Value<int>? otherFixedExpense,
    Value<DateTime?>? survivalModeActivatedAt,
    Value<int?>? partialOnboardingStep,
    Value<int?>? partialOnboardingAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      paymentDate: paymentDate ?? this.paymentDate,
      fixedExpenses: fixedExpenses ?? this.fixedExpenses,
      emergencyFundPct: emergencyFundPct ?? this.emergencyFundPct,
      onboardingCreatedAt: onboardingCreatedAt ?? this.onboardingCreatedAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      rentExpense: rentExpense ?? this.rentExpense,
      utilitiesExpense: utilitiesExpense ?? this.utilitiesExpense,
      internetExpense: internetExpense ?? this.internetExpense,
      phoneExpense: phoneExpense ?? this.phoneExpense,
      otherFixedExpense: otherFixedExpense ?? this.otherFixedExpense,
      survivalModeActivatedAt:
          survivalModeActivatedAt ?? this.survivalModeActivatedAt,
      partialOnboardingStep:
          partialOnboardingStep ?? this.partialOnboardingStep,
      partialOnboardingAt: partialOnboardingAt ?? this.partialOnboardingAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (monthlyIncome.present) {
      map['monthly_income'] = Variable<int>(monthlyIncome.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<int>(paymentDate.value);
    }
    if (fixedExpenses.present) {
      map['fixed_expenses'] = Variable<int>(fixedExpenses.value);
    }
    if (emergencyFundPct.present) {
      map['emergency_fund_pct'] = Variable<double>(emergencyFundPct.value);
    }
    if (onboardingCreatedAt.present) {
      map['onboarding_created_at'] = Variable<DateTime>(
        onboardingCreatedAt.value,
      );
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (reminderHour.present) {
      map['reminder_hour'] = Variable<int>(reminderHour.value);
    }
    if (reminderMinute.present) {
      map['reminder_minute'] = Variable<int>(reminderMinute.value);
    }
    if (rentExpense.present) {
      map['rent_expense'] = Variable<int>(rentExpense.value);
    }
    if (utilitiesExpense.present) {
      map['utilities_expense'] = Variable<int>(utilitiesExpense.value);
    }
    if (internetExpense.present) {
      map['internet_expense'] = Variable<int>(internetExpense.value);
    }
    if (phoneExpense.present) {
      map['phone_expense'] = Variable<int>(phoneExpense.value);
    }
    if (otherFixedExpense.present) {
      map['other_fixed_expense'] = Variable<int>(otherFixedExpense.value);
    }
    if (survivalModeActivatedAt.present) {
      map['survival_mode_activated_at'] = Variable<DateTime>(
        survivalModeActivatedAt.value,
      );
    }
    if (partialOnboardingStep.present) {
      map['partial_onboarding_step'] = Variable<int>(
        partialOnboardingStep.value,
      );
    }
    if (partialOnboardingAt.present) {
      map['partial_onboarding_at'] = Variable<int>(partialOnboardingAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('locale: $locale, ')
          ..write('themeMode: $themeMode, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('monthlyIncome: $monthlyIncome, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('fixedExpenses: $fixedExpenses, ')
          ..write('emergencyFundPct: $emergencyFundPct, ')
          ..write('onboardingCreatedAt: $onboardingCreatedAt, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('rentExpense: $rentExpense, ')
          ..write('utilitiesExpense: $utilitiesExpense, ')
          ..write('internetExpense: $internetExpense, ')
          ..write('phoneExpense: $phoneExpense, ')
          ..write('otherFixedExpense: $otherFixedExpense, ')
          ..write('survivalModeActivatedAt: $survivalModeActivatedAt, ')
          ..write('partialOnboardingStep: $partialOnboardingStep, ')
          ..write('partialOnboardingAt: $partialOnboardingAt')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionPathMeta = const VerificationMeta(
    'collectionPath',
  );
  @override
  late final GeneratedColumn<String> collectionPath = GeneratedColumn<String>(
    'collection_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncOperation, String> operation =
      GeneratedColumn<String>(
        'operation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncOperation>($SyncQueueTable.$converteroperation);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    collectionPath,
    data,
    operation,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('collection_path')) {
      context.handle(
        _collectionPathMeta,
        collectionPath.isAcceptableOrUnknown(
          data['collection_path']!,
          _collectionPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionPathMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      collectionPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_path'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      operation: $SyncQueueTable.$converteroperation.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}operation'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }

  static TypeConverter<SyncOperation, String> $converteroperation =
      const SyncOperationConverter();
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String itemId;
  final String collectionPath;
  final String data;
  final SyncOperation operation;
  final DateTime createdAt;
  const SyncQueueData({
    required this.id,
    required this.itemId,
    required this.collectionPath,
    required this.data,
    required this.operation,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<String>(itemId);
    map['collection_path'] = Variable<String>(collectionPath);
    map['data'] = Variable<String>(data);
    {
      map['operation'] = Variable<String>(
        $SyncQueueTable.$converteroperation.toSql(operation),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      itemId: Value(itemId),
      collectionPath: Value(collectionPath),
      data: Value(data),
      operation: Value(operation),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      collectionPath: serializer.fromJson<String>(json['collectionPath']),
      data: serializer.fromJson<String>(json['data']),
      operation: serializer.fromJson<SyncOperation>(json['operation']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<String>(itemId),
      'collectionPath': serializer.toJson<String>(collectionPath),
      'data': serializer.toJson<String>(data),
      'operation': serializer.toJson<SyncOperation>(operation),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? itemId,
    String? collectionPath,
    String? data,
    SyncOperation? operation,
    DateTime? createdAt,
  }) => SyncQueueData(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    collectionPath: collectionPath ?? this.collectionPath,
    data: data ?? this.data,
    operation: operation ?? this.operation,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      collectionPath: data.collectionPath.present
          ? data.collectionPath.value
          : this.collectionPath,
      data: data.data.present ? data.data.value : this.data,
      operation: data.operation.present ? data.operation.value : this.operation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('collectionPath: $collectionPath, ')
          ..write('data: $data, ')
          ..write('operation: $operation, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, itemId, collectionPath, data, operation, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.collectionPath == this.collectionPath &&
          other.data == this.data &&
          other.operation == this.operation &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> itemId;
  final Value<String> collectionPath;
  final Value<String> data;
  final Value<SyncOperation> operation;
  final Value<DateTime> createdAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.collectionPath = const Value.absent(),
    this.data = const Value.absent(),
    this.operation = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String itemId,
    required String collectionPath,
    required String data,
    required SyncOperation operation,
    required DateTime createdAt,
  }) : itemId = Value(itemId),
       collectionPath = Value(collectionPath),
       data = Value(data),
       operation = Value(operation),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? itemId,
    Expression<String>? collectionPath,
    Expression<String>? data,
    Expression<String>? operation,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (collectionPath != null) 'collection_path': collectionPath,
      if (data != null) 'data': data,
      if (operation != null) 'operation': operation,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? itemId,
    Value<String>? collectionPath,
    Value<String>? data,
    Value<SyncOperation>? operation,
    Value<DateTime>? createdAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      collectionPath: collectionPath ?? this.collectionPath,
      data: data ?? this.data,
      operation: operation ?? this.operation,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (collectionPath.present) {
      map['collection_path'] = Variable<String>(collectionPath.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(
        $SyncQueueTable.$converteroperation.toSql(operation.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('collectionPath: $collectionPath, ')
          ..write('data: $data, ')
          ..write('operation: $operation, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _txIdMeta = const VerificationMeta('txId');
  @override
  late final GeneratedColumn<String> txId = GeneratedColumn<String>(
    'tx_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFixedMeta = const VerificationMeta(
    'isFixed',
  );
  @override
  late final GeneratedColumn<bool> isFixed = GeneratedColumn<bool>(
    'is_fixed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_fixed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<int> goalId = GeneratedColumn<int>(
    'goal_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    txId,
    amount,
    category,
    type,
    note,
    date,
    isFixed,
    isSynced,
    syncedAt,
    createdAt,
    updatedAt,
    goalId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tx_id')) {
      context.handle(
        _txIdMeta,
        txId.isAcceptableOrUnknown(data['tx_id']!, _txIdMeta),
      );
    } else if (isInserting) {
      context.missing(_txIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_fixed')) {
      context.handle(
        _isFixedMeta,
        isFixed.isAcceptableOrUnknown(data['is_fixed']!, _isFixedMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {txId};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      txId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tx_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      isFixed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_fixed'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_id'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String txId;
  final int amount;
  final String category;
  final String type;
  final String? note;
  final DateTime date;
  final bool isFixed;
  final bool isSynced;
  final DateTime? syncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? goalId;
  const Transaction({
    required this.txId,
    required this.amount,
    required this.category,
    required this.type,
    this.note,
    required this.date,
    required this.isFixed,
    required this.isSynced,
    this.syncedAt,
    required this.createdAt,
    required this.updatedAt,
    this.goalId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tx_id'] = Variable<String>(txId);
    map['amount'] = Variable<int>(amount);
    map['category'] = Variable<String>(category);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['date'] = Variable<DateTime>(date);
    map['is_fixed'] = Variable<bool>(isFixed);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || goalId != null) {
      map['goal_id'] = Variable<int>(goalId);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      txId: Value(txId),
      amount: Value(amount),
      category: Value(category),
      type: Value(type),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      date: Value(date),
      isFixed: Value(isFixed),
      isSynced: Value(isSynced),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      goalId: goalId == null && nullToAbsent
          ? const Value.absent()
          : Value(goalId),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      txId: serializer.fromJson<String>(json['txId']),
      amount: serializer.fromJson<int>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      type: serializer.fromJson<String>(json['type']),
      note: serializer.fromJson<String?>(json['note']),
      date: serializer.fromJson<DateTime>(json['date']),
      isFixed: serializer.fromJson<bool>(json['isFixed']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      goalId: serializer.fromJson<int?>(json['goalId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'txId': serializer.toJson<String>(txId),
      'amount': serializer.toJson<int>(amount),
      'category': serializer.toJson<String>(category),
      'type': serializer.toJson<String>(type),
      'note': serializer.toJson<String?>(note),
      'date': serializer.toJson<DateTime>(date),
      'isFixed': serializer.toJson<bool>(isFixed),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'goalId': serializer.toJson<int?>(goalId),
    };
  }

  Transaction copyWith({
    String? txId,
    int? amount,
    String? category,
    String? type,
    Value<String?> note = const Value.absent(),
    DateTime? date,
    bool? isFixed,
    bool? isSynced,
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<int?> goalId = const Value.absent(),
  }) => Transaction(
    txId: txId ?? this.txId,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    type: type ?? this.type,
    note: note.present ? note.value : this.note,
    date: date ?? this.date,
    isFixed: isFixed ?? this.isFixed,
    isSynced: isSynced ?? this.isSynced,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    goalId: goalId.present ? goalId.value : this.goalId,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      txId: data.txId.present ? data.txId.value : this.txId,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      type: data.type.present ? data.type.value : this.type,
      note: data.note.present ? data.note.value : this.note,
      date: data.date.present ? data.date.value : this.date,
      isFixed: data.isFixed.present ? data.isFixed.value : this.isFixed,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('txId: $txId, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('isFixed: $isFixed, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('goalId: $goalId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    txId,
    amount,
    category,
    type,
    note,
    date,
    isFixed,
    isSynced,
    syncedAt,
    createdAt,
    updatedAt,
    goalId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.txId == this.txId &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.type == this.type &&
          other.note == this.note &&
          other.date == this.date &&
          other.isFixed == this.isFixed &&
          other.isSynced == this.isSynced &&
          other.syncedAt == this.syncedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.goalId == this.goalId);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> txId;
  final Value<int> amount;
  final Value<String> category;
  final Value<String> type;
  final Value<String?> note;
  final Value<DateTime> date;
  final Value<bool> isFixed;
  final Value<bool> isSynced;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int?> goalId;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.txId = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.type = const Value.absent(),
    this.note = const Value.absent(),
    this.date = const Value.absent(),
    this.isFixed = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.goalId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String txId,
    required int amount,
    required String category,
    required String type,
    this.note = const Value.absent(),
    required DateTime date,
    this.isFixed = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.goalId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : txId = Value(txId),
       amount = Value(amount),
       category = Value(category),
       type = Value(type),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Transaction> custom({
    Expression<String>? txId,
    Expression<int>? amount,
    Expression<String>? category,
    Expression<String>? type,
    Expression<String>? note,
    Expression<DateTime>? date,
    Expression<bool>? isFixed,
    Expression<bool>? isSynced,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? goalId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (txId != null) 'tx_id': txId,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (type != null) 'type': type,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
      if (isFixed != null) 'is_fixed': isFixed,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (goalId != null) 'goal_id': goalId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? txId,
    Value<int>? amount,
    Value<String>? category,
    Value<String>? type,
    Value<String?>? note,
    Value<DateTime>? date,
    Value<bool>? isFixed,
    Value<bool>? isSynced,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int?>? goalId,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      txId: txId ?? this.txId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
      isFixed: isFixed ?? this.isFixed,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      goalId: goalId ?? this.goalId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (txId.present) {
      map['tx_id'] = Variable<String>(txId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (isFixed.present) {
      map['is_fixed'] = Variable<bool>(isFixed.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<int>(goalId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('txId: $txId, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('isFixed: $isFixed, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('goalId: $goalId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAmountMeta = const VerificationMeta(
    'targetAmount',
  );
  @override
  late final GeneratedColumn<int> targetAmount = GeneratedColumn<int>(
    'target_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    targetAmount,
    targetDate,
    isCompleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(
          data['target_amount']!,
          _targetAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_amount'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final int id;
  final String title;
  final int targetAmount;
  final DateTime targetDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.targetDate,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['target_amount'] = Variable<int>(targetAmount);
    map['target_date'] = Variable<DateTime>(targetDate);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      title: Value(title),
      targetAmount: Value(targetAmount),
      targetDate: Value(targetDate),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      targetAmount: serializer.fromJson<int>(json['targetAmount']),
      targetDate: serializer.fromJson<DateTime>(json['targetDate']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'targetAmount': serializer.toJson<int>(targetAmount),
      'targetDate': serializer.toJson<DateTime>(targetDate),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Goal copyWith({
    int? id,
    String? title,
    int? targetAmount,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Goal(
    id: id ?? this.id,
    title: title ?? this.title,
    targetAmount: targetAmount ?? this.targetAmount,
    targetDate: targetDate ?? this.targetDate,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('targetDate: $targetDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    targetAmount,
    targetDate,
    isCompleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.title == this.title &&
          other.targetAmount == this.targetAmount &&
          other.targetDate == this.targetDate &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<String> title;
  final Value<int> targetAmount;
  final Value<DateTime> targetDate;
  final Value<bool> isCompleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required int targetAmount,
    required DateTime targetDate,
    this.isCompleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : title = Value(title),
       targetAmount = Value(targetAmount),
       targetDate = Value(targetDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? targetAmount,
    Expression<DateTime>? targetDate,
    Expression<bool>? isCompleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (targetDate != null) 'target_date': targetDate,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GoalsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int>? targetAmount,
    Value<DateTime>? targetDate,
    Value<bool>? isCompleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<int>(targetAmount.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('targetDate: $targetDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BudgetLimitsTable extends BudgetLimits
    with TableInfo<$BudgetLimitsTable, BudgetLimit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetLimitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitAmountMeta = const VerificationMeta(
    'limitAmount',
  );
  @override
  late final GeneratedColumn<int> limitAmount = GeneratedColumn<int>(
    'limit_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BudgetCycle, String> cycleType =
      GeneratedColumn<String>(
        'cycle_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('cycle'),
      ).withConverter<BudgetCycle>($BudgetLimitsTable.$convertercycleType);
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    limitAmount,
    cycleType,
    isEnabled,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_limits';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetLimit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('limit_amount')) {
      context.handle(
        _limitAmountMeta,
        limitAmount.isAcceptableOrUnknown(
          data['limit_amount']!,
          _limitAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limitAmountMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetLimit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetLimit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      limitAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_amount'],
      )!,
      cycleType: $BudgetLimitsTable.$convertercycleType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cycle_type'],
        )!,
      ),
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BudgetLimitsTable createAlias(String alias) {
    return $BudgetLimitsTable(attachedDatabase, alias);
  }

  static TypeConverter<BudgetCycle, String> $convertercycleType =
      const BudgetCycleConverter();
}

class BudgetLimit extends DataClass implements Insertable<BudgetLimit> {
  final int id;
  final String category;
  final int limitAmount;
  final BudgetCycle cycleType;
  final bool isEnabled;
  final DateTime updatedAt;
  const BudgetLimit({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.cycleType,
    required this.isEnabled,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category'] = Variable<String>(category);
    map['limit_amount'] = Variable<int>(limitAmount);
    {
      map['cycle_type'] = Variable<String>(
        $BudgetLimitsTable.$convertercycleType.toSql(cycleType),
      );
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BudgetLimitsCompanion toCompanion(bool nullToAbsent) {
    return BudgetLimitsCompanion(
      id: Value(id),
      category: Value(category),
      limitAmount: Value(limitAmount),
      cycleType: Value(cycleType),
      isEnabled: Value(isEnabled),
      updatedAt: Value(updatedAt),
    );
  }

  factory BudgetLimit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetLimit(
      id: serializer.fromJson<int>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      limitAmount: serializer.fromJson<int>(json['limitAmount']),
      cycleType: serializer.fromJson<BudgetCycle>(json['cycleType']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'category': serializer.toJson<String>(category),
      'limitAmount': serializer.toJson<int>(limitAmount),
      'cycleType': serializer.toJson<BudgetCycle>(cycleType),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BudgetLimit copyWith({
    int? id,
    String? category,
    int? limitAmount,
    BudgetCycle? cycleType,
    bool? isEnabled,
    DateTime? updatedAt,
  }) => BudgetLimit(
    id: id ?? this.id,
    category: category ?? this.category,
    limitAmount: limitAmount ?? this.limitAmount,
    cycleType: cycleType ?? this.cycleType,
    isEnabled: isEnabled ?? this.isEnabled,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BudgetLimit copyWithCompanion(BudgetLimitsCompanion data) {
    return BudgetLimit(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      limitAmount: data.limitAmount.present
          ? data.limitAmount.value
          : this.limitAmount,
      cycleType: data.cycleType.present ? data.cycleType.value : this.cycleType,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetLimit(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('limitAmount: $limitAmount, ')
          ..write('cycleType: $cycleType, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, category, limitAmount, cycleType, isEnabled, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetLimit &&
          other.id == this.id &&
          other.category == this.category &&
          other.limitAmount == this.limitAmount &&
          other.cycleType == this.cycleType &&
          other.isEnabled == this.isEnabled &&
          other.updatedAt == this.updatedAt);
}

class BudgetLimitsCompanion extends UpdateCompanion<BudgetLimit> {
  final Value<int> id;
  final Value<String> category;
  final Value<int> limitAmount;
  final Value<BudgetCycle> cycleType;
  final Value<bool> isEnabled;
  final Value<DateTime> updatedAt;
  const BudgetLimitsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.limitAmount = const Value.absent(),
    this.cycleType = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BudgetLimitsCompanion.insert({
    this.id = const Value.absent(),
    required String category,
    required int limitAmount,
    this.cycleType = const Value.absent(),
    this.isEnabled = const Value.absent(),
    required DateTime updatedAt,
  }) : category = Value(category),
       limitAmount = Value(limitAmount),
       updatedAt = Value(updatedAt);
  static Insertable<BudgetLimit> custom({
    Expression<int>? id,
    Expression<String>? category,
    Expression<int>? limitAmount,
    Expression<String>? cycleType,
    Expression<bool>? isEnabled,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (limitAmount != null) 'limit_amount': limitAmount,
      if (cycleType != null) 'cycle_type': cycleType,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BudgetLimitsCompanion copyWith({
    Value<int>? id,
    Value<String>? category,
    Value<int>? limitAmount,
    Value<BudgetCycle>? cycleType,
    Value<bool>? isEnabled,
    Value<DateTime>? updatedAt,
  }) {
    return BudgetLimitsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      cycleType: cycleType ?? this.cycleType,
      isEnabled: isEnabled ?? this.isEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (limitAmount.present) {
      map['limit_amount'] = Variable<int>(limitAmount.value);
    }
    if (cycleType.present) {
      map['cycle_type'] = Variable<String>(
        $BudgetLimitsTable.$convertercycleType.toSql(cycleType.value),
      );
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetLimitsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('limitAmount: $limitAmount, ')
          ..write('cycleType: $cycleType, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelKeyMeta = const VerificationMeta(
    'labelKey',
  );
  @override
  late final GeneratedColumn<String> labelKey = GeneratedColumn<String>(
    'label_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelOverrideMeta = const VerificationMeta(
    'labelOverride',
  );
  @override
  late final GeneratedColumn<String> labelOverride = GeneratedColumn<String>(
    'label_override',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBuiltInMeta = const VerificationMeta(
    'isBuiltIn',
  );
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
    'is_built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isLimitableMeta = const VerificationMeta(
    'isLimitable',
  );
  @override
  late final GeneratedColumn<bool> isLimitable = GeneratedColumn<bool>(
    'is_limitable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_limitable" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expense'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _iconSlugMeta = const VerificationMeta(
    'iconSlug',
  );
  @override
  late final GeneratedColumn<String> iconSlug = GeneratedColumn<String>(
    'icon_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    slug,
    labelKey,
    labelOverride,
    isBuiltIn,
    isLimitable,
    type,
    sortOrder,
    iconSlug,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('label_key')) {
      context.handle(
        _labelKeyMeta,
        labelKey.isAcceptableOrUnknown(data['label_key']!, _labelKeyMeta),
      );
    }
    if (data.containsKey('label_override')) {
      context.handle(
        _labelOverrideMeta,
        labelOverride.isAcceptableOrUnknown(
          data['label_override']!,
          _labelOverrideMeta,
        ),
      );
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
        _isBuiltInMeta,
        isBuiltIn.isAcceptableOrUnknown(data['is_built_in']!, _isBuiltInMeta),
      );
    }
    if (data.containsKey('is_limitable')) {
      context.handle(
        _isLimitableMeta,
        isLimitable.isAcceptableOrUnknown(
          data['is_limitable']!,
          _isLimitableMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('icon_slug')) {
      context.handle(
        _iconSlugMeta,
        iconSlug.isAcceptableOrUnknown(data['icon_slug']!, _iconSlugMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {slug},
  ];
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      labelKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_key'],
      ),
      labelOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_override'],
      ),
      isBuiltIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_built_in'],
      )!,
      isLimitable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_limitable'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      iconSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_slug'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String slug;
  final String? labelKey;
  final String? labelOverride;
  final bool isBuiltIn;
  final bool isLimitable;
  final String type;
  final int sortOrder;
  final String? iconSlug;
  const Category({
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['slug'] = Variable<String>(slug);
    if (!nullToAbsent || labelKey != null) {
      map['label_key'] = Variable<String>(labelKey);
    }
    if (!nullToAbsent || labelOverride != null) {
      map['label_override'] = Variable<String>(labelOverride);
    }
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    map['is_limitable'] = Variable<bool>(isLimitable);
    map['type'] = Variable<String>(type);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || iconSlug != null) {
      map['icon_slug'] = Variable<String>(iconSlug);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      slug: Value(slug),
      labelKey: labelKey == null && nullToAbsent
          ? const Value.absent()
          : Value(labelKey),
      labelOverride: labelOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(labelOverride),
      isBuiltIn: Value(isBuiltIn),
      isLimitable: Value(isLimitable),
      type: Value(type),
      sortOrder: Value(sortOrder),
      iconSlug: iconSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(iconSlug),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
      labelKey: serializer.fromJson<String?>(json['labelKey']),
      labelOverride: serializer.fromJson<String?>(json['labelOverride']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
      isLimitable: serializer.fromJson<bool>(json['isLimitable']),
      type: serializer.fromJson<String>(json['type']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      iconSlug: serializer.fromJson<String?>(json['iconSlug']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'slug': serializer.toJson<String>(slug),
      'labelKey': serializer.toJson<String?>(labelKey),
      'labelOverride': serializer.toJson<String?>(labelOverride),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'isLimitable': serializer.toJson<bool>(isLimitable),
      'type': serializer.toJson<String>(type),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'iconSlug': serializer.toJson<String?>(iconSlug),
    };
  }

  Category copyWith({
    int? id,
    String? slug,
    Value<String?> labelKey = const Value.absent(),
    Value<String?> labelOverride = const Value.absent(),
    bool? isBuiltIn,
    bool? isLimitable,
    String? type,
    int? sortOrder,
    Value<String?> iconSlug = const Value.absent(),
  }) => Category(
    id: id ?? this.id,
    slug: slug ?? this.slug,
    labelKey: labelKey.present ? labelKey.value : this.labelKey,
    labelOverride: labelOverride.present
        ? labelOverride.value
        : this.labelOverride,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    isLimitable: isLimitable ?? this.isLimitable,
    type: type ?? this.type,
    sortOrder: sortOrder ?? this.sortOrder,
    iconSlug: iconSlug.present ? iconSlug.value : this.iconSlug,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      labelKey: data.labelKey.present ? data.labelKey.value : this.labelKey,
      labelOverride: data.labelOverride.present
          ? data.labelOverride.value
          : this.labelOverride,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
      isLimitable: data.isLimitable.present
          ? data.isLimitable.value
          : this.isLimitable,
      type: data.type.present ? data.type.value : this.type,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      iconSlug: data.iconSlug.present ? data.iconSlug.value : this.iconSlug,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('labelKey: $labelKey, ')
          ..write('labelOverride: $labelOverride, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('isLimitable: $isLimitable, ')
          ..write('type: $type, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('iconSlug: $iconSlug')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    slug,
    labelKey,
    labelOverride,
    isBuiltIn,
    isLimitable,
    type,
    sortOrder,
    iconSlug,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.labelKey == this.labelKey &&
          other.labelOverride == this.labelOverride &&
          other.isBuiltIn == this.isBuiltIn &&
          other.isLimitable == this.isLimitable &&
          other.type == this.type &&
          other.sortOrder == this.sortOrder &&
          other.iconSlug == this.iconSlug);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> slug;
  final Value<String?> labelKey;
  final Value<String?> labelOverride;
  final Value<bool> isBuiltIn;
  final Value<bool> isLimitable;
  final Value<String> type;
  final Value<int> sortOrder;
  final Value<String?> iconSlug;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.labelKey = const Value.absent(),
    this.labelOverride = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.isLimitable = const Value.absent(),
    this.type = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.iconSlug = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String slug,
    this.labelKey = const Value.absent(),
    this.labelOverride = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.isLimitable = const Value.absent(),
    this.type = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.iconSlug = const Value.absent(),
  }) : slug = Value(slug);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? slug,
    Expression<String>? labelKey,
    Expression<String>? labelOverride,
    Expression<bool>? isBuiltIn,
    Expression<bool>? isLimitable,
    Expression<String>? type,
    Expression<int>? sortOrder,
    Expression<String>? iconSlug,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (labelKey != null) 'label_key': labelKey,
      if (labelOverride != null) 'label_override': labelOverride,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (isLimitable != null) 'is_limitable': isLimitable,
      if (type != null) 'type': type,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (iconSlug != null) 'icon_slug': iconSlug,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? slug,
    Value<String?>? labelKey,
    Value<String?>? labelOverride,
    Value<bool>? isBuiltIn,
    Value<bool>? isLimitable,
    Value<String>? type,
    Value<int>? sortOrder,
    Value<String?>? iconSlug,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      labelKey: labelKey ?? this.labelKey,
      labelOverride: labelOverride ?? this.labelOverride,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isLimitable: isLimitable ?? this.isLimitable,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      iconSlug: iconSlug ?? this.iconSlug,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (labelKey.present) {
      map['label_key'] = Variable<String>(labelKey.value);
    }
    if (labelOverride.present) {
      map['label_override'] = Variable<String>(labelOverride.value);
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (isLimitable.present) {
      map['is_limitable'] = Variable<bool>(isLimitable.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (iconSlug.present) {
      map['icon_slug'] = Variable<String>(iconSlug.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('labelKey: $labelKey, ')
          ..write('labelOverride: $labelOverride, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('isLimitable: $isLimitable, ')
          ..write('type: $type, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('iconSlug: $iconSlug')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Asia/Jakarta'),
  );
  static const VerificationMeta _baseCurrencyMeta = const VerificationMeta(
    'baseCurrency',
  );
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
    'base_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('IDR'),
  );
  static const VerificationMeta _homeCurrencyMeta = const VerificationMeta(
    'homeCurrency',
  );
  @override
  late final GeneratedColumn<String> homeCurrency = GeneratedColumn<String>(
    'home_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('IDR'),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('id'),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentCountryMeta = const VerificationMeta(
    'currentCountry',
  );
  @override
  late final GeneratedColumn<String> currentCountry = GeneratedColumn<String>(
    'current_country',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ID'),
  );
  static const VerificationMeta _currentCityMeta = const VerificationMeta(
    'currentCity',
  );
  @override
  late final GeneratedColumn<String> currentCity = GeneratedColumn<String>(
    'current_city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _homeCountryMeta = const VerificationMeta(
    'homeCountry',
  );
  @override
  late final GeneratedColumn<String> homeCountry = GeneratedColumn<String>(
    'home_country',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ID'),
  );
  static const VerificationMeta _homeCityMeta = const VerificationMeta(
    'homeCity',
  );
  @override
  late final GeneratedColumn<String> homeCity = GeneratedColumn<String>(
    'home_city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPerantauMeta = const VerificationMeta(
    'isPerantau',
  );
  @override
  late final GeneratedColumn<bool> isPerantau = GeneratedColumn<bool>(
    'is_perantau',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_perantau" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _profileCompletedMeta = const VerificationMeta(
    'profileCompleted',
  );
  @override
  late final GeneratedColumn<bool> profileCompleted = GeneratedColumn<bool>(
    'profile_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("profile_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastSyncedAtMsMeta = const VerificationMeta(
    'lastSyncedAtMs',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAtMs = GeneratedColumn<int>(
    'last_synced_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timezone,
    baseCurrency,
    homeCurrency,
    language,
    displayName,
    status,
    currentCountry,
    currentCity,
    homeCountry,
    homeCity,
    isPerantau,
    profileCompleted,
    schemaVersion,
    lastSyncedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('base_currency')) {
      context.handle(
        _baseCurrencyMeta,
        baseCurrency.isAcceptableOrUnknown(
          data['base_currency']!,
          _baseCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('home_currency')) {
      context.handle(
        _homeCurrencyMeta,
        homeCurrency.isAcceptableOrUnknown(
          data['home_currency']!,
          _homeCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('current_country')) {
      context.handle(
        _currentCountryMeta,
        currentCountry.isAcceptableOrUnknown(
          data['current_country']!,
          _currentCountryMeta,
        ),
      );
    }
    if (data.containsKey('current_city')) {
      context.handle(
        _currentCityMeta,
        currentCity.isAcceptableOrUnknown(
          data['current_city']!,
          _currentCityMeta,
        ),
      );
    }
    if (data.containsKey('home_country')) {
      context.handle(
        _homeCountryMeta,
        homeCountry.isAcceptableOrUnknown(
          data['home_country']!,
          _homeCountryMeta,
        ),
      );
    }
    if (data.containsKey('home_city')) {
      context.handle(
        _homeCityMeta,
        homeCity.isAcceptableOrUnknown(data['home_city']!, _homeCityMeta),
      );
    }
    if (data.containsKey('is_perantau')) {
      context.handle(
        _isPerantauMeta,
        isPerantau.isAcceptableOrUnknown(data['is_perantau']!, _isPerantauMeta),
      );
    }
    if (data.containsKey('profile_completed')) {
      context.handle(
        _profileCompletedMeta,
        profileCompleted.isAcceptableOrUnknown(
          data['profile_completed']!,
          _profileCompletedMeta,
        ),
      );
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at_ms')) {
      context.handle(
        _lastSyncedAtMsMeta,
        lastSyncedAtMs.isAcceptableOrUnknown(
          data['last_synced_at_ms']!,
          _lastSyncedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      baseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency'],
      )!,
      homeCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_currency'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      currentCountry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_country'],
      )!,
      currentCity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_city'],
      ),
      homeCountry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_country'],
      )!,
      homeCity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_city'],
      ),
      isPerantau: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_perantau'],
      )!,
      profileCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}profile_completed'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      lastSyncedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at_ms'],
      ),
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final int id;
  final String timezone;
  final String baseCurrency;
  final String homeCurrency;
  final String language;
  final String? displayName;
  final String? status;
  final String currentCountry;
  final String? currentCity;
  final String homeCountry;
  final String? homeCity;
  final bool isPerantau;
  final bool profileCompleted;
  final int schemaVersion;
  final int? lastSyncedAtMs;
  const Preference({
    required this.id,
    required this.timezone,
    required this.baseCurrency,
    required this.homeCurrency,
    required this.language,
    this.displayName,
    this.status,
    required this.currentCountry,
    this.currentCity,
    required this.homeCountry,
    this.homeCity,
    required this.isPerantau,
    required this.profileCompleted,
    required this.schemaVersion,
    this.lastSyncedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timezone'] = Variable<String>(timezone);
    map['base_currency'] = Variable<String>(baseCurrency);
    map['home_currency'] = Variable<String>(homeCurrency);
    map['language'] = Variable<String>(language);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    map['current_country'] = Variable<String>(currentCountry);
    if (!nullToAbsent || currentCity != null) {
      map['current_city'] = Variable<String>(currentCity);
    }
    map['home_country'] = Variable<String>(homeCountry);
    if (!nullToAbsent || homeCity != null) {
      map['home_city'] = Variable<String>(homeCity);
    }
    map['is_perantau'] = Variable<bool>(isPerantau);
    map['profile_completed'] = Variable<bool>(profileCompleted);
    map['schema_version'] = Variable<int>(schemaVersion);
    if (!nullToAbsent || lastSyncedAtMs != null) {
      map['last_synced_at_ms'] = Variable<int>(lastSyncedAtMs);
    }
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(
      id: Value(id),
      timezone: Value(timezone),
      baseCurrency: Value(baseCurrency),
      homeCurrency: Value(homeCurrency),
      language: Value(language),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      currentCountry: Value(currentCountry),
      currentCity: currentCity == null && nullToAbsent
          ? const Value.absent()
          : Value(currentCity),
      homeCountry: Value(homeCountry),
      homeCity: homeCity == null && nullToAbsent
          ? const Value.absent()
          : Value(homeCity),
      isPerantau: Value(isPerantau),
      profileCompleted: Value(profileCompleted),
      schemaVersion: Value(schemaVersion),
      lastSyncedAtMs: lastSyncedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAtMs),
    );
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      id: serializer.fromJson<int>(json['id']),
      timezone: serializer.fromJson<String>(json['timezone']),
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
      homeCurrency: serializer.fromJson<String>(json['homeCurrency']),
      language: serializer.fromJson<String>(json['language']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      status: serializer.fromJson<String?>(json['status']),
      currentCountry: serializer.fromJson<String>(json['currentCountry']),
      currentCity: serializer.fromJson<String?>(json['currentCity']),
      homeCountry: serializer.fromJson<String>(json['homeCountry']),
      homeCity: serializer.fromJson<String?>(json['homeCity']),
      isPerantau: serializer.fromJson<bool>(json['isPerantau']),
      profileCompleted: serializer.fromJson<bool>(json['profileCompleted']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      lastSyncedAtMs: serializer.fromJson<int?>(json['lastSyncedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timezone': serializer.toJson<String>(timezone),
      'baseCurrency': serializer.toJson<String>(baseCurrency),
      'homeCurrency': serializer.toJson<String>(homeCurrency),
      'language': serializer.toJson<String>(language),
      'displayName': serializer.toJson<String?>(displayName),
      'status': serializer.toJson<String?>(status),
      'currentCountry': serializer.toJson<String>(currentCountry),
      'currentCity': serializer.toJson<String?>(currentCity),
      'homeCountry': serializer.toJson<String>(homeCountry),
      'homeCity': serializer.toJson<String?>(homeCity),
      'isPerantau': serializer.toJson<bool>(isPerantau),
      'profileCompleted': serializer.toJson<bool>(profileCompleted),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'lastSyncedAtMs': serializer.toJson<int?>(lastSyncedAtMs),
    };
  }

  Preference copyWith({
    int? id,
    String? timezone,
    String? baseCurrency,
    String? homeCurrency,
    String? language,
    Value<String?> displayName = const Value.absent(),
    Value<String?> status = const Value.absent(),
    String? currentCountry,
    Value<String?> currentCity = const Value.absent(),
    String? homeCountry,
    Value<String?> homeCity = const Value.absent(),
    bool? isPerantau,
    bool? profileCompleted,
    int? schemaVersion,
    Value<int?> lastSyncedAtMs = const Value.absent(),
  }) => Preference(
    id: id ?? this.id,
    timezone: timezone ?? this.timezone,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    homeCurrency: homeCurrency ?? this.homeCurrency,
    language: language ?? this.language,
    displayName: displayName.present ? displayName.value : this.displayName,
    status: status.present ? status.value : this.status,
    currentCountry: currentCountry ?? this.currentCountry,
    currentCity: currentCity.present ? currentCity.value : this.currentCity,
    homeCountry: homeCountry ?? this.homeCountry,
    homeCity: homeCity.present ? homeCity.value : this.homeCity,
    isPerantau: isPerantau ?? this.isPerantau,
    profileCompleted: profileCompleted ?? this.profileCompleted,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    lastSyncedAtMs: lastSyncedAtMs.present
        ? lastSyncedAtMs.value
        : this.lastSyncedAtMs,
  );
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      id: data.id.present ? data.id.value : this.id,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
      homeCurrency: data.homeCurrency.present
          ? data.homeCurrency.value
          : this.homeCurrency,
      language: data.language.present ? data.language.value : this.language,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      status: data.status.present ? data.status.value : this.status,
      currentCountry: data.currentCountry.present
          ? data.currentCountry.value
          : this.currentCountry,
      currentCity: data.currentCity.present
          ? data.currentCity.value
          : this.currentCity,
      homeCountry: data.homeCountry.present
          ? data.homeCountry.value
          : this.homeCountry,
      homeCity: data.homeCity.present ? data.homeCity.value : this.homeCity,
      isPerantau: data.isPerantau.present
          ? data.isPerantau.value
          : this.isPerantau,
      profileCompleted: data.profileCompleted.present
          ? data.profileCompleted.value
          : this.profileCompleted,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      lastSyncedAtMs: data.lastSyncedAtMs.present
          ? data.lastSyncedAtMs.value
          : this.lastSyncedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('id: $id, ')
          ..write('timezone: $timezone, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('homeCurrency: $homeCurrency, ')
          ..write('language: $language, ')
          ..write('displayName: $displayName, ')
          ..write('status: $status, ')
          ..write('currentCountry: $currentCountry, ')
          ..write('currentCity: $currentCity, ')
          ..write('homeCountry: $homeCountry, ')
          ..write('homeCity: $homeCity, ')
          ..write('isPerantau: $isPerantau, ')
          ..write('profileCompleted: $profileCompleted, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('lastSyncedAtMs: $lastSyncedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timezone,
    baseCurrency,
    homeCurrency,
    language,
    displayName,
    status,
    currentCountry,
    currentCity,
    homeCountry,
    homeCity,
    isPerantau,
    profileCompleted,
    schemaVersion,
    lastSyncedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.id == this.id &&
          other.timezone == this.timezone &&
          other.baseCurrency == this.baseCurrency &&
          other.homeCurrency == this.homeCurrency &&
          other.language == this.language &&
          other.displayName == this.displayName &&
          other.status == this.status &&
          other.currentCountry == this.currentCountry &&
          other.currentCity == this.currentCity &&
          other.homeCountry == this.homeCountry &&
          other.homeCity == this.homeCity &&
          other.isPerantau == this.isPerantau &&
          other.profileCompleted == this.profileCompleted &&
          other.schemaVersion == this.schemaVersion &&
          other.lastSyncedAtMs == this.lastSyncedAtMs);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<int> id;
  final Value<String> timezone;
  final Value<String> baseCurrency;
  final Value<String> homeCurrency;
  final Value<String> language;
  final Value<String?> displayName;
  final Value<String?> status;
  final Value<String> currentCountry;
  final Value<String?> currentCity;
  final Value<String> homeCountry;
  final Value<String?> homeCity;
  final Value<bool> isPerantau;
  final Value<bool> profileCompleted;
  final Value<int> schemaVersion;
  final Value<int?> lastSyncedAtMs;
  const PreferencesCompanion({
    this.id = const Value.absent(),
    this.timezone = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.homeCurrency = const Value.absent(),
    this.language = const Value.absent(),
    this.displayName = const Value.absent(),
    this.status = const Value.absent(),
    this.currentCountry = const Value.absent(),
    this.currentCity = const Value.absent(),
    this.homeCountry = const Value.absent(),
    this.homeCity = const Value.absent(),
    this.isPerantau = const Value.absent(),
    this.profileCompleted = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.lastSyncedAtMs = const Value.absent(),
  });
  PreferencesCompanion.insert({
    this.id = const Value.absent(),
    this.timezone = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.homeCurrency = const Value.absent(),
    this.language = const Value.absent(),
    this.displayName = const Value.absent(),
    this.status = const Value.absent(),
    this.currentCountry = const Value.absent(),
    this.currentCity = const Value.absent(),
    this.homeCountry = const Value.absent(),
    this.homeCity = const Value.absent(),
    this.isPerantau = const Value.absent(),
    this.profileCompleted = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.lastSyncedAtMs = const Value.absent(),
  });
  static Insertable<Preference> custom({
    Expression<int>? id,
    Expression<String>? timezone,
    Expression<String>? baseCurrency,
    Expression<String>? homeCurrency,
    Expression<String>? language,
    Expression<String>? displayName,
    Expression<String>? status,
    Expression<String>? currentCountry,
    Expression<String>? currentCity,
    Expression<String>? homeCountry,
    Expression<String>? homeCity,
    Expression<bool>? isPerantau,
    Expression<bool>? profileCompleted,
    Expression<int>? schemaVersion,
    Expression<int>? lastSyncedAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timezone != null) 'timezone': timezone,
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (homeCurrency != null) 'home_currency': homeCurrency,
      if (language != null) 'language': language,
      if (displayName != null) 'display_name': displayName,
      if (status != null) 'status': status,
      if (currentCountry != null) 'current_country': currentCountry,
      if (currentCity != null) 'current_city': currentCity,
      if (homeCountry != null) 'home_country': homeCountry,
      if (homeCity != null) 'home_city': homeCity,
      if (isPerantau != null) 'is_perantau': isPerantau,
      if (profileCompleted != null) 'profile_completed': profileCompleted,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (lastSyncedAtMs != null) 'last_synced_at_ms': lastSyncedAtMs,
    });
  }

  PreferencesCompanion copyWith({
    Value<int>? id,
    Value<String>? timezone,
    Value<String>? baseCurrency,
    Value<String>? homeCurrency,
    Value<String>? language,
    Value<String?>? displayName,
    Value<String?>? status,
    Value<String>? currentCountry,
    Value<String?>? currentCity,
    Value<String>? homeCountry,
    Value<String?>? homeCity,
    Value<bool>? isPerantau,
    Value<bool>? profileCompleted,
    Value<int>? schemaVersion,
    Value<int?>? lastSyncedAtMs,
  }) {
    return PreferencesCompanion(
      id: id ?? this.id,
      timezone: timezone ?? this.timezone,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      homeCurrency: homeCurrency ?? this.homeCurrency,
      language: language ?? this.language,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      currentCountry: currentCountry ?? this.currentCountry,
      currentCity: currentCity ?? this.currentCity,
      homeCountry: homeCountry ?? this.homeCountry,
      homeCity: homeCity ?? this.homeCity,
      isPerantau: isPerantau ?? this.isPerantau,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      lastSyncedAtMs: lastSyncedAtMs ?? this.lastSyncedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (homeCurrency.present) {
      map['home_currency'] = Variable<String>(homeCurrency.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (currentCountry.present) {
      map['current_country'] = Variable<String>(currentCountry.value);
    }
    if (currentCity.present) {
      map['current_city'] = Variable<String>(currentCity.value);
    }
    if (homeCountry.present) {
      map['home_country'] = Variable<String>(homeCountry.value);
    }
    if (homeCity.present) {
      map['home_city'] = Variable<String>(homeCity.value);
    }
    if (isPerantau.present) {
      map['is_perantau'] = Variable<bool>(isPerantau.value);
    }
    if (profileCompleted.present) {
      map['profile_completed'] = Variable<bool>(profileCompleted.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (lastSyncedAtMs.present) {
      map['last_synced_at_ms'] = Variable<int>(lastSyncedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('id: $id, ')
          ..write('timezone: $timezone, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('homeCurrency: $homeCurrency, ')
          ..write('language: $language, ')
          ..write('displayName: $displayName, ')
          ..write('status: $status, ')
          ..write('currentCountry: $currentCountry, ')
          ..write('currentCity: $currentCity, ')
          ..write('homeCountry: $homeCountry, ')
          ..write('homeCity: $homeCity, ')
          ..write('isPerantau: $isPerantau, ')
          ..write('profileCompleted: $profileCompleted, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('lastSyncedAtMs: $lastSyncedAtMs')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $BudgetLimitsTable budgetLimits = $BudgetLimitsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    syncQueue,
    transactions,
    goals,
    budgetLimits,
    categories,
    preferences,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> locale,
      Value<String> themeMode,
      Value<bool> onboardingCompleted,
      Value<int> monthlyIncome,
      Value<int> paymentDate,
      Value<int> fixedExpenses,
      Value<double> emergencyFundPct,
      Value<DateTime?> onboardingCreatedAt,
      Value<bool> reminderEnabled,
      Value<int> reminderHour,
      Value<int> reminderMinute,
      Value<int> rentExpense,
      Value<int> utilitiesExpense,
      Value<int> internetExpense,
      Value<int> phoneExpense,
      Value<int> otherFixedExpense,
      Value<DateTime?> survivalModeActivatedAt,
      Value<int?> partialOnboardingStep,
      Value<int?> partialOnboardingAt,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> locale,
      Value<String> themeMode,
      Value<bool> onboardingCompleted,
      Value<int> monthlyIncome,
      Value<int> paymentDate,
      Value<int> fixedExpenses,
      Value<double> emergencyFundPct,
      Value<DateTime?> onboardingCreatedAt,
      Value<bool> reminderEnabled,
      Value<int> reminderHour,
      Value<int> reminderMinute,
      Value<int> rentExpense,
      Value<int> utilitiesExpense,
      Value<int> internetExpense,
      Value<int> phoneExpense,
      Value<int> otherFixedExpense,
      Value<DateTime?> survivalModeActivatedAt,
      Value<int?> partialOnboardingStep,
      Value<int?> partialOnboardingAt,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthlyIncome => $composableBuilder(
    column: $table.monthlyIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedExpenses => $composableBuilder(
    column: $table.fixedExpenses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get emergencyFundPct => $composableBuilder(
    column: $table.emergencyFundPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get onboardingCreatedAt => $composableBuilder(
    column: $table.onboardingCreatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rentExpense => $composableBuilder(
    column: $table.rentExpense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get utilitiesExpense => $composableBuilder(
    column: $table.utilitiesExpense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get internetExpense => $composableBuilder(
    column: $table.internetExpense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phoneExpense => $composableBuilder(
    column: $table.phoneExpense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get otherFixedExpense => $composableBuilder(
    column: $table.otherFixedExpense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get survivalModeActivatedAt => $composableBuilder(
    column: $table.survivalModeActivatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partialOnboardingStep => $composableBuilder(
    column: $table.partialOnboardingStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partialOnboardingAt => $composableBuilder(
    column: $table.partialOnboardingAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthlyIncome => $composableBuilder(
    column: $table.monthlyIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedExpenses => $composableBuilder(
    column: $table.fixedExpenses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get emergencyFundPct => $composableBuilder(
    column: $table.emergencyFundPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get onboardingCreatedAt => $composableBuilder(
    column: $table.onboardingCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rentExpense => $composableBuilder(
    column: $table.rentExpense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get utilitiesExpense => $composableBuilder(
    column: $table.utilitiesExpense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get internetExpense => $composableBuilder(
    column: $table.internetExpense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phoneExpense => $composableBuilder(
    column: $table.phoneExpense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get otherFixedExpense => $composableBuilder(
    column: $table.otherFixedExpense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get survivalModeActivatedAt => $composableBuilder(
    column: $table.survivalModeActivatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partialOnboardingStep => $composableBuilder(
    column: $table.partialOnboardingStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partialOnboardingAt => $composableBuilder(
    column: $table.partialOnboardingAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get monthlyIncome => $composableBuilder(
    column: $table.monthlyIncome,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedExpenses => $composableBuilder(
    column: $table.fixedExpenses,
    builder: (column) => column,
  );

  GeneratedColumn<double> get emergencyFundPct => $composableBuilder(
    column: $table.emergencyFundPct,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get onboardingCreatedAt => $composableBuilder(
    column: $table.onboardingCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rentExpense => $composableBuilder(
    column: $table.rentExpense,
    builder: (column) => column,
  );

  GeneratedColumn<int> get utilitiesExpense => $composableBuilder(
    column: $table.utilitiesExpense,
    builder: (column) => column,
  );

  GeneratedColumn<int> get internetExpense => $composableBuilder(
    column: $table.internetExpense,
    builder: (column) => column,
  );

  GeneratedColumn<int> get phoneExpense => $composableBuilder(
    column: $table.phoneExpense,
    builder: (column) => column,
  );

  GeneratedColumn<int> get otherFixedExpense => $composableBuilder(
    column: $table.otherFixedExpense,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get survivalModeActivatedAt => $composableBuilder(
    column: $table.survivalModeActivatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get partialOnboardingStep => $composableBuilder(
    column: $table.partialOnboardingStep,
    builder: (column) => column,
  );

  GeneratedColumn<int> get partialOnboardingAt => $composableBuilder(
    column: $table.partialOnboardingAt,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<int> monthlyIncome = const Value.absent(),
                Value<int> paymentDate = const Value.absent(),
                Value<int> fixedExpenses = const Value.absent(),
                Value<double> emergencyFundPct = const Value.absent(),
                Value<DateTime?> onboardingCreatedAt = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<int> rentExpense = const Value.absent(),
                Value<int> utilitiesExpense = const Value.absent(),
                Value<int> internetExpense = const Value.absent(),
                Value<int> phoneExpense = const Value.absent(),
                Value<int> otherFixedExpense = const Value.absent(),
                Value<DateTime?> survivalModeActivatedAt = const Value.absent(),
                Value<int?> partialOnboardingStep = const Value.absent(),
                Value<int?> partialOnboardingAt = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                locale: locale,
                themeMode: themeMode,
                onboardingCompleted: onboardingCompleted,
                monthlyIncome: monthlyIncome,
                paymentDate: paymentDate,
                fixedExpenses: fixedExpenses,
                emergencyFundPct: emergencyFundPct,
                onboardingCreatedAt: onboardingCreatedAt,
                reminderEnabled: reminderEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                rentExpense: rentExpense,
                utilitiesExpense: utilitiesExpense,
                internetExpense: internetExpense,
                phoneExpense: phoneExpense,
                otherFixedExpense: otherFixedExpense,
                survivalModeActivatedAt: survivalModeActivatedAt,
                partialOnboardingStep: partialOnboardingStep,
                partialOnboardingAt: partialOnboardingAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<int> monthlyIncome = const Value.absent(),
                Value<int> paymentDate = const Value.absent(),
                Value<int> fixedExpenses = const Value.absent(),
                Value<double> emergencyFundPct = const Value.absent(),
                Value<DateTime?> onboardingCreatedAt = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<int> rentExpense = const Value.absent(),
                Value<int> utilitiesExpense = const Value.absent(),
                Value<int> internetExpense = const Value.absent(),
                Value<int> phoneExpense = const Value.absent(),
                Value<int> otherFixedExpense = const Value.absent(),
                Value<DateTime?> survivalModeActivatedAt = const Value.absent(),
                Value<int?> partialOnboardingStep = const Value.absent(),
                Value<int?> partialOnboardingAt = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                locale: locale,
                themeMode: themeMode,
                onboardingCompleted: onboardingCompleted,
                monthlyIncome: monthlyIncome,
                paymentDate: paymentDate,
                fixedExpenses: fixedExpenses,
                emergencyFundPct: emergencyFundPct,
                onboardingCreatedAt: onboardingCreatedAt,
                reminderEnabled: reminderEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                rentExpense: rentExpense,
                utilitiesExpense: utilitiesExpense,
                internetExpense: internetExpense,
                phoneExpense: phoneExpense,
                otherFixedExpense: otherFixedExpense,
                survivalModeActivatedAt: survivalModeActivatedAt,
                partialOnboardingStep: partialOnboardingStep,
                partialOnboardingAt: partialOnboardingAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String itemId,
      required String collectionPath,
      required String data,
      required SyncOperation operation,
      required DateTime createdAt,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> itemId,
      Value<String> collectionPath,
      Value<String> data,
      Value<SyncOperation> operation,
      Value<DateTime> createdAt,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectionPath => $composableBuilder(
    column: $table.collectionPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncOperation, SyncOperation, String>
  get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectionPath => $composableBuilder(
    column: $table.collectionPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get collectionPath => $composableBuilder(
    column: $table.collectionPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncOperation, String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> collectionPath = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<SyncOperation> operation = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                itemId: itemId,
                collectionPath: collectionPath,
                data: data,
                operation: operation,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemId,
                required String collectionPath,
                required String data,
                required SyncOperation operation,
                required DateTime createdAt,
              }) => SyncQueueCompanion.insert(
                id: id,
                itemId: itemId,
                collectionPath: collectionPath,
                data: data,
                operation: operation,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String txId,
      required int amount,
      required String category,
      required String type,
      Value<String?> note,
      required DateTime date,
      Value<bool> isFixed,
      Value<bool> isSynced,
      Value<DateTime?> syncedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int?> goalId,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> txId,
      Value<int> amount,
      Value<String> category,
      Value<String> type,
      Value<String?> note,
      Value<DateTime> date,
      Value<bool> isFixed,
      Value<bool> isSynced,
      Value<DateTime?> syncedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int?> goalId,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get txId => $composableBuilder(
    column: $table.txId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFixed => $composableBuilder(
    column: $table.isFixed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get txId => $composableBuilder(
    column: $table.txId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFixed => $composableBuilder(
    column: $table.isFixed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get txId =>
      $composableBuilder(column: $table.txId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isFixed =>
      $composableBuilder(column: $table.isFixed, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> txId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> isFixed = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int?> goalId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                txId: txId,
                amount: amount,
                category: category,
                type: type,
                note: note,
                date: date,
                isFixed: isFixed,
                isSynced: isSynced,
                syncedAt: syncedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                goalId: goalId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String txId,
                required int amount,
                required String category,
                required String type,
                Value<String?> note = const Value.absent(),
                required DateTime date,
                Value<bool> isFixed = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int?> goalId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                txId: txId,
                amount: amount,
                category: category,
                type: type,
                note: note,
                date: date,
                isFixed: isFixed,
                isSynced: isSynced,
                syncedAt: syncedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                goalId: goalId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      required String title,
      required int targetAmount,
      required DateTime targetDate,
      Value<bool> isCompleted,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<int> targetAmount,
      Value<DateTime> targetDate,
      Value<bool> isCompleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> targetAmount = const Value.absent(),
                Value<DateTime> targetDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                title: title,
                targetAmount: targetAmount,
                targetDate: targetDate,
                isCompleted: isCompleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required int targetAmount,
                required DateTime targetDate,
                Value<bool> isCompleted = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => GoalsCompanion.insert(
                id: id,
                title: title,
                targetAmount: targetAmount,
                targetDate: targetDate,
                isCompleted: isCompleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;
typedef $$BudgetLimitsTableCreateCompanionBuilder =
    BudgetLimitsCompanion Function({
      Value<int> id,
      required String category,
      required int limitAmount,
      Value<BudgetCycle> cycleType,
      Value<bool> isEnabled,
      required DateTime updatedAt,
    });
typedef $$BudgetLimitsTableUpdateCompanionBuilder =
    BudgetLimitsCompanion Function({
      Value<int> id,
      Value<String> category,
      Value<int> limitAmount,
      Value<BudgetCycle> cycleType,
      Value<bool> isEnabled,
      Value<DateTime> updatedAt,
    });

class $$BudgetLimitsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetLimitsTable> {
  $$BudgetLimitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitAmount => $composableBuilder(
    column: $table.limitAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BudgetCycle, BudgetCycle, String>
  get cycleType => $composableBuilder(
    column: $table.cycleType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetLimitsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetLimitsTable> {
  $$BudgetLimitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitAmount => $composableBuilder(
    column: $table.limitAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleType => $composableBuilder(
    column: $table.cycleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetLimitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetLimitsTable> {
  $$BudgetLimitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get limitAmount => $composableBuilder(
    column: $table.limitAmount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BudgetCycle, String> get cycleType =>
      $composableBuilder(column: $table.cycleType, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BudgetLimitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetLimitsTable,
          BudgetLimit,
          $$BudgetLimitsTableFilterComposer,
          $$BudgetLimitsTableOrderingComposer,
          $$BudgetLimitsTableAnnotationComposer,
          $$BudgetLimitsTableCreateCompanionBuilder,
          $$BudgetLimitsTableUpdateCompanionBuilder,
          (
            BudgetLimit,
            BaseReferences<_$AppDatabase, $BudgetLimitsTable, BudgetLimit>,
          ),
          BudgetLimit,
          PrefetchHooks Function()
        > {
  $$BudgetLimitsTableTableManager(_$AppDatabase db, $BudgetLimitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetLimitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetLimitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetLimitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> limitAmount = const Value.absent(),
                Value<BudgetCycle> cycleType = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BudgetLimitsCompanion(
                id: id,
                category: category,
                limitAmount: limitAmount,
                cycleType: cycleType,
                isEnabled: isEnabled,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String category,
                required int limitAmount,
                Value<BudgetCycle> cycleType = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                required DateTime updatedAt,
              }) => BudgetLimitsCompanion.insert(
                id: id,
                category: category,
                limitAmount: limitAmount,
                cycleType: cycleType,
                isEnabled: isEnabled,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetLimitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetLimitsTable,
      BudgetLimit,
      $$BudgetLimitsTableFilterComposer,
      $$BudgetLimitsTableOrderingComposer,
      $$BudgetLimitsTableAnnotationComposer,
      $$BudgetLimitsTableCreateCompanionBuilder,
      $$BudgetLimitsTableUpdateCompanionBuilder,
      (
        BudgetLimit,
        BaseReferences<_$AppDatabase, $BudgetLimitsTable, BudgetLimit>,
      ),
      BudgetLimit,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String slug,
      Value<String?> labelKey,
      Value<String?> labelOverride,
      Value<bool> isBuiltIn,
      Value<bool> isLimitable,
      Value<String> type,
      Value<int> sortOrder,
      Value<String?> iconSlug,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> slug,
      Value<String?> labelKey,
      Value<String?> labelOverride,
      Value<bool> isBuiltIn,
      Value<bool> isLimitable,
      Value<String> type,
      Value<int> sortOrder,
      Value<String?> iconSlug,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelKey => $composableBuilder(
    column: $table.labelKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelOverride => $composableBuilder(
    column: $table.labelOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLimitable => $composableBuilder(
    column: $table.isLimitable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconSlug => $composableBuilder(
    column: $table.iconSlug,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelKey => $composableBuilder(
    column: $table.labelKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelOverride => $composableBuilder(
    column: $table.labelOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLimitable => $composableBuilder(
    column: $table.isLimitable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconSlug => $composableBuilder(
    column: $table.iconSlug,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get labelKey =>
      $composableBuilder(column: $table.labelKey, builder: (column) => column);

  GeneratedColumn<String> get labelOverride => $composableBuilder(
    column: $table.labelOverride,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBuiltIn =>
      $composableBuilder(column: $table.isBuiltIn, builder: (column) => column);

  GeneratedColumn<bool> get isLimitable => $composableBuilder(
    column: $table.isLimitable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get iconSlug =>
      $composableBuilder(column: $table.iconSlug, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String?> labelKey = const Value.absent(),
                Value<String?> labelOverride = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<bool> isLimitable = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> iconSlug = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                slug: slug,
                labelKey: labelKey,
                labelOverride: labelOverride,
                isBuiltIn: isBuiltIn,
                isLimitable: isLimitable,
                type: type,
                sortOrder: sortOrder,
                iconSlug: iconSlug,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String slug,
                Value<String?> labelKey = const Value.absent(),
                Value<String?> labelOverride = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<bool> isLimitable = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> iconSlug = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                slug: slug,
                labelKey: labelKey,
                labelOverride: labelOverride,
                isBuiltIn: isBuiltIn,
                isLimitable: isLimitable,
                type: type,
                sortOrder: sortOrder,
                iconSlug: iconSlug,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      Value<int> id,
      Value<String> timezone,
      Value<String> baseCurrency,
      Value<String> homeCurrency,
      Value<String> language,
      Value<String?> displayName,
      Value<String?> status,
      Value<String> currentCountry,
      Value<String?> currentCity,
      Value<String> homeCountry,
      Value<String?> homeCity,
      Value<bool> isPerantau,
      Value<bool> profileCompleted,
      Value<int> schemaVersion,
      Value<int?> lastSyncedAtMs,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<int> id,
      Value<String> timezone,
      Value<String> baseCurrency,
      Value<String> homeCurrency,
      Value<String> language,
      Value<String?> displayName,
      Value<String?> status,
      Value<String> currentCountry,
      Value<String?> currentCity,
      Value<String> homeCountry,
      Value<String?> homeCity,
      Value<bool> isPerantau,
      Value<bool> profileCompleted,
      Value<int> schemaVersion,
      Value<int?> lastSyncedAtMs,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeCurrency => $composableBuilder(
    column: $table.homeCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentCountry => $composableBuilder(
    column: $table.currentCountry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentCity => $composableBuilder(
    column: $table.currentCity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeCountry => $composableBuilder(
    column: $table.homeCountry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeCity => $composableBuilder(
    column: $table.homeCity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPerantau => $composableBuilder(
    column: $table.isPerantau,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get profileCompleted => $composableBuilder(
    column: $table.profileCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAtMs => $composableBuilder(
    column: $table.lastSyncedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeCurrency => $composableBuilder(
    column: $table.homeCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentCountry => $composableBuilder(
    column: $table.currentCountry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentCity => $composableBuilder(
    column: $table.currentCity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeCountry => $composableBuilder(
    column: $table.homeCountry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeCity => $composableBuilder(
    column: $table.homeCity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPerantau => $composableBuilder(
    column: $table.isPerantau,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get profileCompleted => $composableBuilder(
    column: $table.profileCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAtMs => $composableBuilder(
    column: $table.lastSyncedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get homeCurrency => $composableBuilder(
    column: $table.homeCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get currentCountry => $composableBuilder(
    column: $table.currentCountry,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentCity => $composableBuilder(
    column: $table.currentCity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get homeCountry => $composableBuilder(
    column: $table.homeCountry,
    builder: (column) => column,
  );

  GeneratedColumn<String> get homeCity =>
      $composableBuilder(column: $table.homeCity, builder: (column) => column);

  GeneratedColumn<bool> get isPerantau => $composableBuilder(
    column: $table.isPerantau,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get profileCompleted => $composableBuilder(
    column: $table.profileCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncedAtMs => $composableBuilder(
    column: $table.lastSyncedAtMs,
    builder: (column) => column,
  );
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            Preference,
            BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
          ),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<String> baseCurrency = const Value.absent(),
                Value<String> homeCurrency = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String> currentCountry = const Value.absent(),
                Value<String?> currentCity = const Value.absent(),
                Value<String> homeCountry = const Value.absent(),
                Value<String?> homeCity = const Value.absent(),
                Value<bool> isPerantau = const Value.absent(),
                Value<bool> profileCompleted = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int?> lastSyncedAtMs = const Value.absent(),
              }) => PreferencesCompanion(
                id: id,
                timezone: timezone,
                baseCurrency: baseCurrency,
                homeCurrency: homeCurrency,
                language: language,
                displayName: displayName,
                status: status,
                currentCountry: currentCountry,
                currentCity: currentCity,
                homeCountry: homeCountry,
                homeCity: homeCity,
                isPerantau: isPerantau,
                profileCompleted: profileCompleted,
                schemaVersion: schemaVersion,
                lastSyncedAtMs: lastSyncedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<String> baseCurrency = const Value.absent(),
                Value<String> homeCurrency = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String> currentCountry = const Value.absent(),
                Value<String?> currentCity = const Value.absent(),
                Value<String> homeCountry = const Value.absent(),
                Value<String?> homeCity = const Value.absent(),
                Value<bool> isPerantau = const Value.absent(),
                Value<bool> profileCompleted = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int?> lastSyncedAtMs = const Value.absent(),
              }) => PreferencesCompanion.insert(
                id: id,
                timezone: timezone,
                baseCurrency: baseCurrency,
                homeCurrency: homeCurrency,
                language: language,
                displayName: displayName,
                status: status,
                currentCountry: currentCountry,
                currentCity: currentCity,
                homeCountry: homeCountry,
                homeCity: homeCity,
                isPerantau: isPerantau,
                profileCompleted: profileCompleted,
                schemaVersion: schemaVersion,
                lastSyncedAtMs: lastSyncedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        Preference,
        BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
      ),
      Preference,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$BudgetLimitsTableTableManager get budgetLimits =>
      $$BudgetLimitsTableTableManager(_db, _db.budgetLimits);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
}
