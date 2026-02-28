type cfg = {
  url?: string,
  bearerToken?: string,
  httpReqTimeoutMillis?: int,
  maxNumRetries?: int,
  retryBackoffMs?: int,
  retryBaseMs?: int,
  retryCeilingMs?: int,
  enableChecksumAddresses?: bool,
}

module QueryTypes = {
  type query
}

module ResponseTypes = {
  type event
  type eventResponse
}

type query = QueryTypes.query
type eventResponse = ResponseTypes.eventResponse

//Todo, add bindings for these types
type streamConfig
type queryResponse
type queryResponseStream
type eventStream
type t = {
  getHeight: unit => promise<int>,
  collect: (~query: query, ~config: streamConfig) => promise<queryResponse>,
  collectEvents: (~query: query, ~config: streamConfig) => promise<eventResponse>,
  collectParquet: (~path: string, ~query: query, ~config: streamConfig) => promise<unit>,
  get: (~query: query) => promise<queryResponse>,
  getEvents: (~query: query) => promise<eventResponse>,
  stream: (~query: query, ~config: streamConfig) => promise<queryResponseStream>,
  streamEvents: (~query: query, ~config: streamConfig) => promise<eventStream>,
}

@module("@envio-dev/hypersync-client") @scope("HypersyncClient") external new: cfg => t = "new"

let make = (~url, ~apiToken, ~httpReqTimeoutMillis, ~maxNumRetries) =>
  new({
    url,
    enableChecksumAddresses: true,
    bearerToken: apiToken,
    httpReqTimeoutMillis,
    maxNumRetries,
  })

module Decoder = {
  type decodedRaw

  type decodedEvent = {
    indexed: array<decodedRaw>,
    body: array<decodedRaw>,
  }

  type log
  type t = {
    enableChecksummedAddresses: unit => unit,
    disableChecksummedAddresses: unit => unit,
    decodeLogs: array<log> => promise<array<Nullable.t<decodedEvent>>>,
    decodeLogsSync: array<log> => array<Nullable.t<decodedEvent>>,
    decodeEvents: array<ResponseTypes.event> => promise<array<Nullable.t<decodedEvent>>>,
    decodeEventsSync: array<ResponseTypes.event> => array<Nullable.t<decodedEvent>>,
  }

  @module("@envio-dev/hypersync-client") @scope("Decoder")
  external fromSignatures: array<string> => t = "fromSignatures"
}
