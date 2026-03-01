module Chain = {
  type t = int

  external toChainId: t => int = "%identity"

  let toString = chainId => chainId->Int.toString
}

type t<'a> = Belt.Map.Int.t<'a>

let fromArrayUnsafe: array<(Chain.t, 'a)> => t<'a> = arr => {
  arr->Belt.Map.Int.fromArray
}

let get: (t<'a>, Chain.t) => 'a = (self, chain) =>
  switch Belt.Map.Int.get(self, chain) {
  | Some(v) => v
  | None =>
    // Should be unreachable, since we validate on Chain.t creation
    // Still throw just in case something went wrong
    JsError.throwWithMessage("No chain with id " ++ chain->Chain.toString ++ " found in chain map")
  }

let set: (t<'a>, Chain.t, 'a) => t<'a> = (map, chain, v) => Belt.Map.Int.set(map, chain, v)
let values: t<'a> => array<'a> = map => Belt.Map.Int.valuesToArray(map)
let keys: t<'a> => array<Chain.t> = map => Belt.Map.Int.keysToArray(map)
let entries: t<'a> => array<(Chain.t, 'a)> = map => Belt.Map.Int.toArray(map)
let has: (t<'a>, Chain.t) => bool = (map, chain) => Belt.Map.Int.has(map, chain)
let map: (t<'a>, 'a => 'b) => t<'b> = (map, fn) => Belt.Map.Int.map(map, fn)
let mapWithKey: (t<'a>, (Chain.t, 'a) => 'b) => t<'b> = (map, fn) => Belt.Map.Int.mapWithKey(map, fn)
let size: t<'a> => int = map => Belt.Map.Int.size(map)
let update: (t<'a>, Chain.t, 'a => 'a) => t<'a> = (map, chain, updateFn) =>
  Belt.Map.Int.update(map, chain, opt => opt->Option.map(updateFn))
