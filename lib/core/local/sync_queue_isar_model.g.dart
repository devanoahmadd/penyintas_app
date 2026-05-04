// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_isar_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncQueueIsarModelCollection on Isar {
  IsarCollection<SyncQueueIsarModel> get syncQueueIsarModels =>
      this.collection();
}

const SyncQueueIsarModelSchema = CollectionSchema(
  name: r'SyncQueueIsarModel',
  id: -1446050416347064240,
  properties: {
    r'collectionPath': PropertySchema(
      id: 0,
      name: r'collectionPath',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'data': PropertySchema(
      id: 2,
      name: r'data',
      type: IsarType.string,
    ),
    r'itemId': PropertySchema(
      id: 3,
      name: r'itemId',
      type: IsarType.string,
    ),
    r'operation': PropertySchema(
      id: 4,
      name: r'operation',
      type: IsarType.byte,
      enumMap: _SyncQueueIsarModeloperationEnumValueMap,
    )
  },
  estimateSize: _syncQueueIsarModelEstimateSize,
  serialize: _syncQueueIsarModelSerialize,
  deserialize: _syncQueueIsarModelDeserialize,
  deserializeProp: _syncQueueIsarModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _syncQueueIsarModelGetId,
  getLinks: _syncQueueIsarModelGetLinks,
  attach: _syncQueueIsarModelAttach,
  version: '3.1.0+1',
);

int _syncQueueIsarModelEstimateSize(
  SyncQueueIsarModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.collectionPath.length * 3;
  bytesCount += 3 + object.data.length * 3;
  bytesCount += 3 + object.itemId.length * 3;
  return bytesCount;
}

void _syncQueueIsarModelSerialize(
  SyncQueueIsarModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.collectionPath);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.data);
  writer.writeString(offsets[3], object.itemId);
  writer.writeByte(offsets[4], object.operation.index);
}

SyncQueueIsarModel _syncQueueIsarModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncQueueIsarModel();
  object.collectionPath = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.data = reader.readString(offsets[2]);
  object.id = id;
  object.itemId = reader.readString(offsets[3]);
  object.operation = _SyncQueueIsarModeloperationValueEnumMap[
          reader.readByteOrNull(offsets[4])] ??
      SyncOperation.create;
  return object;
}

P _syncQueueIsarModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (_SyncQueueIsarModeloperationValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncOperation.create) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SyncQueueIsarModeloperationEnumValueMap = {
  'create': 0,
  'update': 1,
  'delete': 2,
};
const _SyncQueueIsarModeloperationValueEnumMap = {
  0: SyncOperation.create,
  1: SyncOperation.update,
  2: SyncOperation.delete,
};

Id _syncQueueIsarModelGetId(SyncQueueIsarModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncQueueIsarModelGetLinks(
    SyncQueueIsarModel object) {
  return [];
}

void _syncQueueIsarModelAttach(
    IsarCollection<dynamic> col, Id id, SyncQueueIsarModel object) {
  object.id = id;
}

extension SyncQueueIsarModelQueryWhereSort
    on QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QWhere> {
  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncQueueIsarModelQueryWhere
    on QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QWhereClause> {
  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterWhereClause>
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

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterWhereClause>
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

extension SyncQueueIsarModelQueryFilter
    on QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QFilterCondition> {
  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      collectionPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'collectionPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      collectionPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'collectionPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      collectionPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'collectionPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      collectionPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'collectionPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      collectionPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'collectionPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      collectionPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'collectionPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      collectionPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'collectionPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      collectionPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'collectionPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      collectionPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'collectionPath',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      collectionPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'collectionPath',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      dataEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'data',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      dataGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'data',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      dataLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'data',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      dataBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'data',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      dataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'data',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      dataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'data',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      dataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'data',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      dataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'data',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      dataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'data',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      dataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'data',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      itemIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      itemIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      itemIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      itemIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'itemId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      itemIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      itemIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      itemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      itemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'itemId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      itemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      itemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'itemId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      operationEqualTo(SyncOperation value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'operation',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      operationGreaterThan(
    SyncOperation value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'operation',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      operationLessThan(
    SyncOperation value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'operation',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterFilterCondition>
      operationBetween(
    SyncOperation lower,
    SyncOperation upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'operation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SyncQueueIsarModelQueryObject
    on QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QFilterCondition> {}

extension SyncQueueIsarModelQueryLinks
    on QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QFilterCondition> {}

extension SyncQueueIsarModelQuerySortBy
    on QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QSortBy> {
  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      sortByCollectionPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionPath', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      sortByCollectionPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionPath', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      sortByData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'data', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      sortByDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'data', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      sortByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      sortByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      sortByOperation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operation', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      sortByOperationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operation', Sort.desc);
    });
  }
}

extension SyncQueueIsarModelQuerySortThenBy
    on QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QSortThenBy> {
  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      thenByCollectionPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionPath', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      thenByCollectionPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionPath', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      thenByData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'data', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      thenByDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'data', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      thenByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      thenByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      thenByOperation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operation', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QAfterSortBy>
      thenByOperationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operation', Sort.desc);
    });
  }
}

extension SyncQueueIsarModelQueryWhereDistinct
    on QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QDistinct> {
  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QDistinct>
      distinctByCollectionPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'collectionPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QDistinct>
      distinctByData({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'data', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QDistinct>
      distinctByItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QDistinct>
      distinctByOperation() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'operation');
    });
  }
}

extension SyncQueueIsarModelQueryProperty
    on QueryBuilder<SyncQueueIsarModel, SyncQueueIsarModel, QQueryProperty> {
  QueryBuilder<SyncQueueIsarModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncQueueIsarModel, String, QQueryOperations>
      collectionPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'collectionPath');
    });
  }

  QueryBuilder<SyncQueueIsarModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<SyncQueueIsarModel, String, QQueryOperations> dataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'data');
    });
  }

  QueryBuilder<SyncQueueIsarModel, String, QQueryOperations> itemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemId');
    });
  }

  QueryBuilder<SyncQueueIsarModel, SyncOperation, QQueryOperations>
      operationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'operation');
    });
  }
}
