type logLevelBuiltin = [
  | #trace
  | #debug
  | #info
  | #warn
  | #error
  | #fatal
]
@genType
type logLevelUser = [
  | // NOTE: pino does better when these are all lowercase - some parts of the code lower case logs.
  #udebug
  | #uinfo
  | #uwarn
  | #uerror
]
type logLevel = [logLevelBuiltin | logLevelUser]

type pinoMessageBlob
type pinoMessageBlobWithError
@genType
type t = {
  trace: pinoMessageBlob => unit,
  debug: pinoMessageBlob => unit,
  info: pinoMessageBlob => unit,
  warn: pinoMessageBlob => unit,
  error: pinoMessageBlob => unit,
  fatal: pinoMessageBlob => unit,
}
@send external errorExn: (t, pinoMessageBlobWithError) => unit = "error"

// Bind to the 'level' property getter
@get external getLevel: t => logLevel = "level"

@ocaml.doc(`Get the available logging levels`) @get
external levels: t => 'a = "levels"

// Bind to the 'level' property setter
@set external setLevel: (t, logLevel) => unit = "level"

let createPinoMessageWithError = (message, err): pinoMessageBlobWithError => {
  //See https://github.com/pinojs/pino-std-serializers for standard pino serializers
  //for common objects. We have also defined the serializer in this format in the
  // serializers type below: `type serializers = {err: JSON.t => JSON.t}`
  Utils.magic({
    "msg": message,
    "err": err,
  })
}

module Transport = {
  type t
  type optionsObject

  // NOTE: this config is pretty polymorphic - so keeping this as all optional fields.
  type rec transportTarget = {
    target?: string,
    targets?: array<transportTarget>,
    options?: optionsObject,
    levels?: dict<int>,
    level?: logLevel,
  }
  @module("pino")
  external make: transportTarget => t = "transport"
}

@module external makeWithTransport: Transport.t => t = "pino"

type hooks = {logMethod: (array<string>, string, logLevel) => unit}

type formatters = {
  level: (string, int) => JSON.t,
  bindings: JSON.t => JSON.t,
  log: JSON.t => JSON.t,
}

type serializers = {err: JSON.t => JSON.t}

type options = {
  name?: string,
  level?: logLevel,
  customLevels?: dict<int>,
  useOnlyCustomLevels?: bool,
  depthLimit?: int,
  edgeLimit?: int,
  mixin?: unit => JSON.t,
  mixinMergeStrategy?: (JSON.t, JSON.t) => JSON.t,
  redact?: array<string>,
  hooks?: hooks,
  formatters?: formatters,
  serializers?: serializers,
  msgPrefix?: string,
  base?: JSON.t,
  enabled?: bool,
  crlf?: bool,
  timestamp?: bool,
  messageKey?: string,
}

@module external make: options => t = "pino"
@module external makeWithOptionsAndTransport: (options, Transport.t) => t = "pino"

type childParams
@send external child: (t, childParams) => t = "child"

module ECS = {
  @module
  external make: 'a => options = "@elastic/ecs-pino-format"
}

/**
Jank solution to make logs use console log wrather than stream.write so that ink 
can render the logs statically.
*/
module MultiStreamLogger = {
  type stream = {write: string => unit}
  type multiStream = {stream: stream, level: logLevel}
  type multiStreamRes
  @module("pino") external multistream: array<multiStream> => multiStreamRes = "multistream"

  @module external makeWithMultiStream: (options, multiStreamRes) => t = "pino"

  type destinationOpts = {
    dest: string, //file path
    sync: bool,
    mkdir: bool,
  }
  @module("pino") external destination: destinationOpts => stream = "destination"

  type prettyFactoryOpts = {...options, customColors?: string}
  @module("pino-pretty")
  external prettyFactory: prettyFactoryOpts => string => string = "prettyFactory"

}
