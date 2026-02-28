module Utils = {
  external magic: 'a => 'b = "%identity"
}

module Crypto = {
  type t
  @module external crypto: t = "crypto"

  type hashAlgo = string

  type hash
  @send external createHash: (t, hashAlgo) => hash = "createHash"

  type hashedData
  @send external update: (hash, string) => hashedData = "update"

  type digestOptions = string
  @send external digest: (hashedData, digestOptions) => string = "digest"

}

module Make = (Indexer: Indexer.S) => {
  type log

  type makeEvent = (~blockHash: string) => Internal.event

  type logConstructor

  type composedEventConstructor = (
    ~chainId: int,
    ~blockTimestamp: int,
    ~blockNumber: int,
    ~transactionIndex: int,
    ~logIndex: int,
  ) => logConstructor

  type block

  type t

  type contractAddressesAndEventNames

}
