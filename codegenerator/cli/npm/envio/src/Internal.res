type bytes

type eventParams
type eventBlock
type eventTransaction

@genType
type genericEvent<'params, 'block, 'transaction>

type event = genericEvent<eventParams, eventBlock, eventTransaction>

external fromGenericEvent: genericEvent<'a, 'b, 'c> => event = "%identity"

type loaderReturn

@genType
type genericLoaderArgs<'event, 'context>
@genType
type genericLoader<'args, 'loaderReturn> = 'args => promise<'loaderReturn>

type loaderContext
type loaderArgs = genericLoaderArgs<event, loaderContext>
type loader = genericLoader<loaderArgs, loaderReturn>

@genType
type genericContractRegisterArgs<'event, 'context>
@genType
type genericContractRegister<'args> = 'args => unit

type contractRegisterContext
type contractRegisterArgs = genericContractRegisterArgs<event, contractRegisterContext>
type contractRegister = genericContractRegister<contractRegisterArgs>

@genType
type genericHandlerArgs<'event, 'context, 'loaderReturn>
@genType
type genericHandler<'args> = 'args => promise<unit>

type handlerContext
type handlerArgs = genericHandlerArgs<event, handlerContext, loaderReturn>
type handler = genericHandler<handlerArgs>

@genType
type genericHandlerWithLoader<'loader, 'handler, 'eventFilters>

// This is private so it's not manually constructed internally
// The idea is that it can only be coerced from fuel/evmEventConfig
// and it can include their fields. We prevent manual creation,
// so the fields are not overwritten and we can safely cast the type back to fuel/evmEventConfig
type eventConfig

type fuelEventKind
type fuelEventConfig
type fuelContractConfig

type topicSelection = {
  topic0: array<EvmTypes.Hex.t>,
  topic1: array<EvmTypes.Hex.t>,
  topic2: array<EvmTypes.Hex.t>,
  topic3: array<EvmTypes.Hex.t>,
}

type eventFiltersArgs

type eventFilters

type evmEventConfig
type evmContractConfig

type eventItem

@genType
type fuelSupplyParams
@genType
type fuelTransferParams

type entity

@genType.import(("./bindings/OpaqueTypes.ts", "invalid"))
type noEventFilters
