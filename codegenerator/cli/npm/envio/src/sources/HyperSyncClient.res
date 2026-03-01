type cfg

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
type t

@obj
external makeCfg: (
  ~url: string=?,
  ~bearerToken: string=?,
  ~httpReqTimeoutMillis: int=?,
  ~maxNumRetries: int=?,
  ~retryBackoffMs: int=?,
  ~retryBaseMs: int=?,
  ~retryCeilingMs: int=?,
  ~enableChecksumAddresses: bool=?,
) => cfg = ""

@module("@envio-dev/hypersync-client") @scope("HypersyncClient") external new: cfg => t = "new"

let make = (~url, ~apiToken, ~httpReqTimeoutMillis, ~maxNumRetries) =>
  new(
    makeCfg(
      ~url,
      ~enableChecksumAddresses=true,
      ~bearerToken=apiToken,
      ~httpReqTimeoutMillis,
      ~maxNumRetries,
    ),
  )

module Decoder = {
  type decodedRaw

  type decodedEvent

  type log
  type t

  @module("@envio-dev/hypersync-client") @scope("Decoder")
  external fromSignatures: array<string> => t = "fromSignatures"
}
