module Utils = {
  external magic: 'a => 'b = "%identity"
}

module Crypto = {
  type t
  @module external crypto: t = "crypto"

  type hashAlgo = | @as("sha3-256") Sha3_256

  type hash
  @send external createHash: (t, hashAlgo) => hash = "createHash"

  type hashedData
  @send external update: (hash, string) => hashedData = "update"

  type digestOptions = | @as("hex") Hex
  @send external digest: (hashedData, digestOptions) => string = "digest"

}

module Make = (Indexer: Indexer.S) => {
  open Indexer
  type log = {
    eventItem: Internal.eventItem,
    srcAddress: Address.t,
    transactionHash: string,
  }

  type makeEvent = (~blockHash: string) => Internal.event

  type logConstructor = {
    transactionHash: string,
    makeEvent: makeEvent,
    logIndex: int,
    srcAddress: Address.t,
    eventConfig: Internal.evmEventConfig,
  }

  type composedEventConstructor = (
    ~chainId: int,
    ~blockTimestamp: int,
    ~blockNumber: int,
    ~transactionIndex: int,
    ~logIndex: int,
  ) => logConstructor

  type block = {
    blockNumber: int,
    blockTimestamp: int,
    blockHash: string,
    logs: array<log>,
  }

  type t = {
    chainConfig: Config.chainConfig,
    blocks: array<block>,
    maxBlocksReturned: int,
    blockTimestampInterval: int,
  }

  type contractAddressesAndEventNames = {
    addresses: array<Address.t>,
    eventKeys: array<string>,
  }

}
