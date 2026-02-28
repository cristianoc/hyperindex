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

  let pad = s => "0x" ++ s

  let hashKeccak256 = (input, ~toString) =>
    crypto
    ->createHash(Sha3_256)
    ->update(input->toString)
    ->digest(Hex)
    ->pad

  let hashKeccak256Int = hashKeccak256(~toString=int => int->Int.toString, _)
  let anyToString = a => a->JSON.stringifyAny->Option.getOrThrow
  let hashKeccak256Any = hashKeccak256(~toString=anyToString, _)
  let hashKeccak256Compound = (previousHash, input) =>
    input->hashKeccak256(~toString=v => anyToString(v) ++ previousHash)
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

  let getLast = arr => arr->Array.get(arr->Array.length - 1)

  let getBlockHash = (~previousHash, ~logConstructors: array<logConstructor>) =>
    logConstructors->Array.reduce(previousHash, (accum, current) => {
      accum->Crypto.hashKeccak256Compound(current.transactionHash)
    })

  let zeroKeccak = Crypto.hashKeccak256Int(0)
  let getHeight = (self: t) =>
    self.blocks
    ->getLast
    ->Option.mapOr(0, b => b.blockNumber)

  let getBlocks = (self: t, ~fromBlock, ~toBlock) => {
    self.blocks
    ->Array.filter(b =>
      b.blockNumber >= fromBlock &&
        switch toBlock {
        | Some(toBlock) => b.blockNumber <= toBlock
        | None => true
        }
    )
    ->Array.filterWithIndex((_, i) => i < self.maxBlocksReturned)
  }

  let getBlock = (self: t, ~blockNumber) =>
    self.blocks->Array.find(b => b.blockNumber == blockNumber)

  let arrayHas = (arr, v) => arr->Array.find(item => item == v)->Option.isSome

  type contractAddressesAndEventNames = {
    addresses: array<Address.t>,
    eventKeys: array<string>,
  }

  let getEventKey = (eventConfig: Internal.eventConfig) => {
    eventConfig.contractName ++ "_" ++ eventConfig.id
  }

  let getLogsFromBlocks = (
    blocks: array<block>,
    ~addressesAndEventNames: array<contractAddressesAndEventNames>,
  ) => {
    blocks->Array.flatMap(b =>
      b.logs->Array.filterMap(l => {
        let isLogInConfig = addressesAndEventNames->Array.reduce(
          false,
          (prev, {addresses, eventKeys}) => {
            prev ||
            (addresses->arrayHas(l.srcAddress) &&
              eventKeys->arrayHas(getEventKey(l.eventItem.eventConfig)))
          },
        )
        if isLogInConfig {
          Some(l.eventItem)
        } else {
          None
        }
      })
    )
  }

}
