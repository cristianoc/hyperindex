type primitive
type derived
@unboxed
type fieldType =
  | @as("INTEGER") Integer
  | @as("TEXT") Text
  | @as("SERIAL") Serial
  | Custom(string)

type field = {
  fieldName: string,
  fieldType: fieldType,
  isPrimaryKey: bool,
  isIndex: bool,
  linkedEntity: option<string>,
}

type derivedFromField = {
  derivedFromEntity: string,
  derivedFromField: string,
}
type fieldOrDerived = field

let mkField = (
  ~isPrimaryKey=false,
  ~isIndex=false,
  fieldName,
  fieldType,
) =>
  {
    fieldName,
    fieldType,
    isPrimaryKey,
    isIndex,
    linkedEntity: None,
  }

let getUserDefinedFieldName = (field: fieldOrDerived) => field.fieldName

let isLinkedEntityField = field => field.linkedEntity->Option.isSome

let getDbFieldName = field =>
  field->isLinkedEntityField ? field.fieldName ++ "_id" : field.fieldName

let getFieldName = (field: fieldOrDerived) => field->getDbFieldName

type table = {
  tableName: string,
  schemaName: string,
  fields: array<fieldOrDerived>,
  compositeIndices: array<array<string>>,
}

let mkTable = (tableName, ~schemaName, ~fields) => {
  tableName,
  schemaName,
  fields,
  compositeIndices: [],
}

let getPrimaryKeyFieldNames = table =>
  table.fields->Array.filterMap(field =>
    field.isPrimaryKey ? Some(field.fieldName) : None
  )

let getFields = table => table.fields

let getLinkedEntityFields = table =>
  table.fields->Array.filterMap(field =>
    switch field.linkedEntity {
    | Some(linkedEntityName) => Some((field, linkedEntityName))
    | None => None
    }
  )

let getDerivedFromFields = _table => []

let getFieldByName = (table, fieldName) =>
  table.fields->Array.find(field => field->getUserDefinedFieldName === fieldName)

let getFieldByDbName = (table, dbFieldName) =>
  table.fields->Array.find(field => field->getDbFieldName === dbFieldName)

exception NonExistingTableField(string)

/*
Gets all composite indicies (whether they are single indices or not)
And maps the fields defined to their actual db name (some have _id suffix)
*/
let getUnfilteredCompositeIndicesUnsafe = (table): array<array<string>> => {
  table.compositeIndices->Array.map(compositeIndex =>
    compositeIndex->Array.map(userDefinedFieldName =>
      switch table->getFieldByName(userDefinedFieldName) {
      | Some(field) => field->getFieldName
      | None => throw(NonExistingTableField(userDefinedFieldName)) //Unexpected should be validated in schema parser
      }
    )
  )
}

type sqlParams<'entity>

@obj
external makeSqlParams: (
  ~dbSchema: S.t<'entity>,
  ~quotedFieldNames: array<string>,
  ~quotedNonPrimaryFieldNames: array<string>,
  ~arrayFieldTypes: array<string>,
  ~hasArrayField: bool,
) => sqlParams<'entity> = ""

let toSqlParams = (table: table, ~schema) => {
  let quotedFieldNames = []
  let quotedNonPrimaryFieldNames = []
  let arrayFieldTypes = []
  let hasArrayField = ref(false)

  let dbSchema: S.t<Dict.t<unknown>> = S.schema(s =>
    switch schema->S.classify {
    | Object({items}) =>
      let dict = Dict.make()
      items->Belt.Array.forEach(({location, inlinedLocation, schema}) => {
        let rec coerceSchema = schema =>
          switch schema->S.classify {
          | BigInt => Utils.Schema.dbBigint->S.toUnknown
          | Option(child)
          | Null(child) =>
            S.null(child->coerceSchema)->S.toUnknown
          | Array(child) => {
              hasArrayField := true
              S.array(child->coerceSchema)->S.toUnknown
            }
          | JSON(_) => {
              hasArrayField := true
              schema
            }
          | Bool =>
            // Workaround for https://github.com/porsager/postgres/issues/471
            S.union([
              S.literal(1)->S.shape(_ => true),
              S.literal(0)->S.shape(_ => false),
            ])->S.toUnknown
          | _ => schema
          }

        let field = switch table->getFieldByDbName(location) {
        | Some(field) => field
        | None => throw(NonExistingTableField(location))
        }

        quotedFieldNames
        ->Array.push(inlinedLocation)
        ->ignore
        switch field {
        | {isPrimaryKey: false} =>
          quotedNonPrimaryFieldNames
          ->Array.push(inlinedLocation)
          ->ignore
        | _ => ()
        }

        arrayFieldTypes
        ->Array.push(
          switch field {
          | f =>
            switch f.fieldType {
            | Custom(fieldType) => `${(Text :> string)}[]::${(fieldType :> string)}`
            | fieldType => (fieldType :> string)
            }
          } ++ "[]",
        )
        ->ignore
        dict->Dict.set(location, s.matches(schema->coerceSchema))
      })
      dict
    | _ => JsError.throwWithMessage("Failed creating db schema. Expected an object schema for table")
    }
  )

  makeSqlParams(
    ~dbSchema=dbSchema->(Utils.magic: S.t<dict<unknown>> => S.t<'entity>),
    ~quotedFieldNames,
    ~quotedNonPrimaryFieldNames,
    ~arrayFieldTypes,
    ~hasArrayField=hasArrayField.contents,
  )
}

/*
Gets all single indicies
And maps the fields defined to their actual db name (some have _id suffix)
*/
let getSingleIndices = (table): array<string> => {
  let indexFields = table.fields->Array.filterMap(field =>
    field.isIndex ? Some(field->getDbFieldName) : None
  )

  table
  ->getUnfilteredCompositeIndicesUnsafe
  //get all composite indices with only 1 field defined
  //this is still a single index
  ->Array.filter(cidx => cidx->Array.length == 1)
  ->Array.concat([indexFields])
  ->Utils.Array.flatten
  ->Set.fromArray
  ->Set.toArray
  ->Array.toSorted((a, b) =>
    if a < b {
      -1.
    } else if a > b {
      1.
    } else {
      0.
    }
  )
}

/*
Gets all composite indicies
And maps the fields defined to their actual db name (some have _id suffix)
*/
let getCompositeIndices = (table): array<array<string>> => {
  table
  ->getUnfilteredCompositeIndicesUnsafe
  ->Array.filter(ind => ind->Array.length > 1)
}

module PostgresInterop = {
  type pgFn<'payload, 'return> = (Postgres.sql, 'payload) => promise<'return>
  type batchSetFn<'a> = (Postgres.sql, array<'a>) => promise<unit>
  external eval: string => 'a = "eval"

}
