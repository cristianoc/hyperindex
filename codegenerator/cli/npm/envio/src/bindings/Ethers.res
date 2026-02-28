type abi = EvmTypes.Abi.t

@deprecated("Use Address.t instead. The type will be removed in v3")
type ethAddress = Address.t
@deprecated("Use Address.Evm.fromStringOrThrow instead. The function will be removed in v3")
let getAddressFromStringUnsafe = Address.Evm.fromStringOrThrow

type txHash = string

module Constants = {
  @module("ethers") @scope("ethers") external zeroHash: string = "ZeroHash"
  @module("ethers") @scope("ethers") external zeroAddress: Address.t = "ZeroAddress"
}

module Addresses = {
  @genType
  let mockAddresses = [
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
    "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
    "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
    "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
    "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955",
    "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f",
    "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720",
    "0xBcd4042DE499D14e55001CcbB24a551F3b954096",
    "0x71bE63f3384f5fb98995898A86B02Fb2426c5788",
    "0xFABB0ac9d68B0B445fB7357272Ff202C5651694a",
    "0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec",
    "0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097",
    "0xcd3B766CCDd6AE721141F452C550Ca635964ce71",
    "0x2546BcD3c84621e976D8185a91A922aE77ECEc30",
    "0xbDA5747bFD65F08deb54cb465eB87D40e51B197E",
    "0xdD2FD4581271e230360230F9337D5c0430Bf44C0",
    "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",
  ]->Belt.Array.map(getAddressFromStringUnsafe)
  @genType
  let defaultAddress =
    mockAddresses[0]
}

module Filter = {
  type t
}

module CombinedFilter = {
  type combinedFilterRecord
}

type log

type transaction

type minimumParseableLogData

type logDescription<'a>

module Network = {
  type t

  @module("ethers") @new
  external make: (~name: string, ~chainId: int) => t = "Network"

  @module("ethers") @scope("Network")
  external fromChainId: (~chainId: int) => t = "from"
}

module JsonRpcProvider = {
  type t

  type rpcOptions

  @module("ethers") @scope("ethers") @new
  external makeWithOptions: (~rpcUrl: string, ~network: Network.t, ~options: rpcOptions) => t =
    "JsonRpcProvider"

  @send
  external getLogs: (t, ~filter: Filter.t) => promise<array<log>> = "getLogs"

  @send
  external getTransaction: (t, ~transactionHash: string) => promise<transaction> = "getTransaction"

  type block

  @send
  external getBlock: (t, int) => promise<Nullable.t<block>> = "getBlock"
}
