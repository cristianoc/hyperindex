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
  | #udebug
  | #uinfo
  | #uwarn
  | #uerror
]
type logLevel = [logLevelBuiltin | logLevelUser]

type pinoMessageBlob
type pinoMessageBlobWithError
@genType
type t

@send external errorExn: (t, pinoMessageBlobWithError) => unit = "error"
@get external getLevel: t => logLevel = "level"
@get external levels: t => 'a = "levels"
@set external setLevel: (t, logLevel) => unit = "level"

let createPinoMessageWithError = (message, err): pinoMessageBlobWithError =>
  Utils.magic({
    "msg": message,
    "err": err,
  })

module Transport = {
  type t
  type transportTarget

  @module("pino")
  external make: transportTarget => t = "transport"
}

@module external makeWithTransport: Transport.t => t = "pino"

type options

@module external make: options => t = "pino"
@module external makeWithOptionsAndTransport: (options, Transport.t) => t = "pino"

type childParams
@send external child: (t, childParams) => t = "child"

module ECS = {
  @module
  external make: 'a => options = "@elastic/ecs-pino-format"
}

module MultiStreamLogger = {
  type stream
  type multiStream
  type multiStreamRes
  @module("pino") external multistream: array<multiStream> => multiStreamRes = "multistream"

  @module external makeWithMultiStream: (options, multiStreamRes) => t = "pino"

  type destinationOpts
  @module("pino") external destination: destinationOpts => stream = "destination"

  type prettyFactoryOpts
  @module("pino-pretty")
  external prettyFactory: prettyFactoryOpts => string => string = "prettyFactory"
}
