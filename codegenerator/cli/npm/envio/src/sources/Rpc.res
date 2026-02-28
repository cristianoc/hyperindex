type hex = string
external number: string => int = "Number"

module GetLogs = {
  @unboxed
  type topicFilter = Single(hex) | Multiple(array<hex>) | @as(null) Null
  type topicQuery = array<topicFilter>
  type param = {
    fromBlock: int,
    toBlock: int,
    address: array<Address.t>,
    topics: topicQuery,
    // blockHash?: string,
  }

  type log = {
    address: Address.t,
    topics: array<hex>,
    data: hex,
    blockNumber: int,
    transactionHash: hex,
    transactionIndex: int,
    blockHash: hex,
    logIndex: int,
    removed: bool,
  }

}

module GetBlockByNumber = {
  type block = {
    difficulty: option<bigint>,
    extraData: hex,
    gasLimit: bigint,
    gasUsed: bigint,
    hash: hex,
    logsBloom: hex,
    miner: Address.t,
    mixHash: option<hex>,
    nonce: option<bigint>,
    number: int,
    parentHash: hex,
    receiptsRoot: hex,
    sha3Uncles: hex,
    size: bigint,
    stateRoot: hex,
    timestamp: int,
    totalDifficulty: option<bigint>,
    transactions: array<JSON.t>,
    transactionsRoot: hex,
    uncles: option<array<hex>>,
  }

}

module GetBlockHeight = {
}
