type sql

type sslOptions

let sslOptionsSchema: S.schema<sslOptions> =
  S.json(~validate=false)->(Utils.magic: S.schema<JSON.t> => S.schema<sslOptions>)

type poolConfig

@module
external makeSql: (~config: poolConfig) => sql = "postgres"

@send external beginSql: (sql, sql => array<promise<unit>>) => promise<unit> = "begin"

@send external unsafe: (sql, string) => promise<'a> = "unsafe"
@send
external preparedUnsafe: (sql, string, unknown, @as(json`{prepare: true}`) _) => promise<'a> =
  "unsafe"
