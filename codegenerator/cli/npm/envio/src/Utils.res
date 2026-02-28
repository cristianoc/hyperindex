external magic: 'a => 'b = "%identity"

let delay = milliseconds =>
  Promise.make((resolve, _reject) => {
    ignore(setTimeout(_ => {
      resolve()
    }, milliseconds))
  })

module Object = {
  // Define a type for the property descriptor
  type propertyDescriptor<'a> = {
    configurable?: bool,
    enumerable?: bool,
    writable?: bool,
    value?: 'a,
    get?: unit => 'a,
    set?: 'a => unit,
  }

  @val @scope("Object")
  external defineProperty: ('obj, string, propertyDescriptor<'a>) => 'obj = "defineProperty"
}

module Option = {}

module Tuple = {
}

module Dict = {
  @get_index
  /**
    It's the same as `Js.Dict.get` but it doesn't have runtime overhead to check if the key exists.
   */
  external dangerouslyGetNonOption: (dict<'a>, string) => option<'a> = ""

  let merge: (dict<'a>, dict<'a>) => dict<'a> = %raw(`(dictA, dictB) => ({...dictA, ...dictB})`)

  let deleteInPlace: (dict<'a>, string) => unit = %raw(`(dict, key) => {
      delete dict[key];
    }
  `)

  let updateImmutable: (
    dict<'a>,
    string,
    'a,
  ) => dict<'a> = %raw(`(dict, key, value) => ({...dict, [key]: value})`)

  let shallowCopy: dict<'a> => dict<'a> = %raw(`(dict) => ({...dict})`)
}

module Math = {
  let minOptInt = (a, b) =>
    switch (a, b) {
    | (Some(a), Some(b)) => Pervasives.min(a, b)->Some
    | (Some(a), None) => Some(a)
    | (None, Some(b)) => Some(b)
    | (None, None) => None
    }
}

module Array = {
  @val external jsArrayCreate: int => array<'a> = "Array"

  /* Given a comaprator and two sorted lists, combine them into a single sorted list */
  let mergeSorted = (f: ('a, 'a) => bool, xs: array<'a>, ys: array<'a>) => {
    if Array.length(xs) == 0 {
      ys
    } else if Array.length(ys) == 0 {
      xs
    } else {
      let n = Array.length(xs) + Array.length(ys)
      let result = jsArrayCreate(n)

      let rec loop = (i, j, k) => {
        if i < Array.length(xs) && j < Array.length(ys) {
          if f(xs->Array.getUnsafe(i), ys->Array.getUnsafe(j)) {
            result[k] = xs->Array.getUnsafe(i)
            loop(i + 1, j, k + 1)
          } else {
            result[k] = ys->Array.getUnsafe(j)
            loop(i, j + 1, k + 1)
          }
        } else if i < Array.length(xs) {
          result[k] = xs->Array.getUnsafe(i)
          loop(i + 1, j, k + 1)
        } else if j < Array.length(ys) {
          result[k] = ys->Array.getUnsafe(j)
          loop(i, j + 1, k + 1)
        }
      }

      loop(0, 0, 0)
      result
    }
  }

  /**
  Creates a shallow copy of the array and sets the value at the given index
  */
  let setIndexImmutable = (arr: array<'a>, index: int, value: 'a): array<'a> => {
    let shallowCopy = arr->Belt.Array.copy
    shallowCopy->Array.setUnsafe(index, value)
    shallowCopy
  }

  let transposeResults = (results: array<result<'a, 'b>>): result<array<'a>, 'b> => {
    let rec loop = (index: int, output: array<'a>): result<array<'a>, 'b> => {
      if index >= Array.length(results) {
        Ok(output)
      } else {
        switch results->Array.getUnsafe(index) {
        | Ok(value) => {
            output[index] = value
            loop(index + 1, output)
          }
        | Error(_) as err => err->(magic: result<'a, 'b> => result<array<'a>, 'b>)
        }
      }
    }

    loop(0, Belt.Array.makeUninitializedUnsafe(results->Array.length))
  }

  /**
Helper to check if a value exists in an array
*/
  let includes = (arr: array<'a>, val: 'a) =>
    arr->Array.find(item => item == val)->Belt.Option.isSome

  let isEmpty = (arr: array<_>) =>
    switch arr {
    | [] => true
    | _ => false
    }

  let awaitEach = async (arr: array<'a>, fn: 'a => promise<unit>) => {
    for i in 0 to arr->Array.length - 1 {
      let item = arr->Array.getUnsafe(i)
      await item->fn
    }
  }

  /**
  Creates a new array removing the item at the given index

  Index > array length or < 0 results in a copy of the array
  */
  let removeAtIndex = (array, index) => {
    if index < 0 {
      array->Array.copy
    } else {
    array
    ->Array.slice(~start=0, ~end=index)
    ->Array.concat(array->Array.slice(~start=index + 1))
  }
  }

  let last = (arr: array<'a>): option<'a> => arr->Belt.Array.get(arr->Array.length - 1)

  let findReverseWithIndex = (arr: array<'a>, fn: 'a => bool): option<('a, int)> => {
    let rec loop = (index: int) => {
      if index < 0 {
        None
      } else {
        let item = arr->Array.getUnsafe(index)
        if fn(item) {
          Some((item, index))
        } else {
          loop(index - 1)
        }
      }
    }
    loop(arr->Array.length - 1)
  }

  /** 
  Currently a bug in rescript if you ignore the return value of spliceInPlace 
  https://github.com/rescript-lang/rescript-compiler/issues/6991
  */
  @send
  external spliceInPlace: (array<'a>, ~pos: int, ~remove: int) => array<'a> = "splice"

  /**
  Interleaves an array with a separator

  interleave([1, 2, 3], 0) -> [1, 0, 2, 0, 3]
  */
  let interleave = (arr: array<'a>, separator: 'a) => {
    let interleaved = []
    arr->Array.forEachWithIndex((v, i) => {
      interleaved->Array.push(v)->ignore
      if i < arr->Array.length - 1 {
        interleaved->Array.push(separator)->ignore
      }
    })
    interleaved
  }

  @send
  external flatten: (array<array<'a>>, @as(1) _) => array<'a> = "flat"
}

module String = {
  let capitalize = str => {
    str->String.slice(~start=0, ~end=1)->String.toUpperCase ++
      str->String.slice(~start=1)
  }
}

module Result = {
  let forEach = (result, fn) => {
    switch result {
    | Ok(v) => fn(v)
    | Error(_) => ()
    }
    result
  }
}

/**
Useful when an unsafe unwrap is needed on Result type
and Error holds an exn. This is better than Result.getExn
because the excepion is not just NOT_FOUND but will rather
bet the actual underlying exn
*/
let unwrapResultExn = res =>
  switch res {
  | Ok(v) => v
  | Error(exn) => exn->throw
  }

external queueMicrotask: (unit => unit) => unit = "queueMicrotask"

module Schema = {
  let getNonOptionalFieldNames = schema => {
    let acc = []
    switch schema->S.classify {
    | Object({items}) =>
      items->Belt.Array.forEach(item => {
        switch item.schema->S.classify {
        // Check for null, since we generate S.null schema for db serializing
        // In the future it should be changed to Option only
        | Null(_) => ()
        | Option(_) => ()
        | _ => acc->Belt.Array.push(item.location)
        }
      })
    | _ => ()
    }
    acc
  }

  let getCapitalizedFieldNames = schema => {
    switch schema->S.classify {
    | Object({items}) => items->Belt.Array.map(item => item.location->String.capitalize)
    | _ => []
    }
  }

  let dbBigint =
    S.string
    ->S.setName("BigInt")
    ->S.transform(s => {
      parser: string =>
        try %raw("BigInt(string)") catch {
        | _ => s.fail("The string is not valid BigInt")
        },
      serializer: bigint => bigint->BigInt.toString,
    })

  // Don't use S.unknown, since it's not serializable to json
  // In a nutshell, this is completely unsafe.
  let dbDate =
    S.json(~validate=false)
    ->(magic: S.t<JSON.t> => S.t<Date.t>)
    ->S.preprocess(_ => {serializer: date => date->magic->Date.toISOString})

  // When trying to serialize data to Json pg type, it will fail with
  // PostgresError: column "params" is of type json but expression is of type boolean
  // If there's bool or null on the root level. It works fine as object field values.
  let coerceToJsonPgType = schema => {
    schema->S.preprocess(s => {
      switch s.schema->S.classify {
      // This is a workaround for Fuel Bytes type
      | Unknown => {serializer: _ => %raw(`"null"`)}
      | Bool => {
          serializer: unknown => {
            if unknown === %raw(`false`) {
              %raw(`"false"`)
            } else if unknown === %raw(`true`) {
              %raw(`"true"`)
            } else {
              unknown
            }
          },
        }
      | _ => {}
      }
    })
  }
}

module Set = {
  type t<'value>

  /*
   * Constructor
   */
  @ocaml.doc("Creates a new `Set` object.") @new
  external make: unit => t<'value> = "Set"

  @ocaml.doc("Creates a new `Set` object.") @new
  external fromArray: array<'value> => t<'value> = "Set"

  /*
   * Instance properties
   */
  @ocaml.doc("Returns the number of values in the `Set` object.") @get
  external size: t<'value> => int = "size"

  /*
   * Instance methods
   */
  @ocaml.doc("Appends `value` to the `Set` object. Returns the `Set` object with added value.")
  @send
  external add: (t<'value>, 'value) => t<'value> = "add"

  let addMany = (set, values) => values->Belt.Array.forEach(value => set->add(value)->ignore)

  @ocaml.doc("Removes all elements from the `Set` object.") @send
  external clear: t<'value> => unit = "clear"

  @ocaml.doc(
    "Removes the element associated to the `value` and returns a boolean asserting whether an element was successfully removed or not. `Set.prototype.has(value)` will return `false` afterwards."
  )
  @send
  external delete: (t<'value>, 'value) => bool = "delete"

  @ocaml.doc(
    "Returns a boolean asserting whether an element is present with the given value in the `Set` object or not."
  )
  @send
  external has: (t<'value>, 'value) => bool = "has"

  external toArray: t<'a> => array<'a> = "Array.from"

  /*
   * Iteration methods
   */
  /*
/// NOTE - if we need iteration we can add this back - currently it requires the `rescript-js-iterator` library.
@ocaml.doc(
  "Returns a new iterator object that yields the **values** for each element in the `Set` object in insertion order."
)
@send
external values: t<'value> => Js_iterator.t<'value> = "values"

@ocaml.doc("An alias for `Set.prototype.values()`.") @send
external keys: t<'value> => Js_iterator.t<'value> = "values"

@ocaml.doc("Returns a new iterator object that contains **an array of [value, value]** for each element in the `Set` object, in insertion order.

This is similar to the [Map](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map) object, so that each entry's `key` is the same as its `value` for a `Set`.")
@send
external entries: t<'value> => Js_iterator.t<('value, 'value)> = "entries"
*/
  @ocaml.doc(
    "Calls `callbackFn` once for each value present in the `Set` object, in insertion order."
  )
  @send
  external forEach: (t<'value>, 'value => unit) => unit = "forEach"

  @ocaml.doc(
    "Calls `callbackFn` once for each value present in the `Set` object, in insertion order."
  )
  @send
  external forEachWithSet: (t<'value>, ('value, 'value, t<'value>) => unit) => unit = "forEach"
}

module WeakMap = {
  type t<'k, 'v> = WeakMap.t<'k, 'v>

  @new external make: unit => t<'k, 'v> = "WeakMap"

  @send external get: (t<'k, 'v>, 'k) => option<'v> = "get"
  @send external unsafeGet: (t<'k, 'v>, 'k) => 'v = "get"
  @send external has: (t<'k, 'v>, 'k) => bool = "has"
  @send external set: (t<'k, 'v>, 'k, 'v) => t<'k, 'v> = "set"
}

module Map = {
  type t<'k, 'v> = Map.t<'k, 'v>

  @new external make: unit => t<'k, 'v> = "Map"

  @send external get: (t<'k, 'v>, 'k) => option<'v> = "get"
  @send external unsafeGet: (t<'k, 'v>, 'k) => 'v = "get"
  @send external has: (t<'k, 'v>, 'k) => bool = "has"
  @send external set: (t<'k, 'v>, 'k, 'v) => t<'k, 'v> = "set"
  @send external delete: (t<'k, 'v>, 'k) => bool = "delete"
}

module BigInt = {
  let fromString = str => {
    try {
      Some(%raw("BigInt(str)"))
    } catch {
    | _ => None
    }
  }

  module Bitwise = {
    @@warning("-27")
    let shift_left = (a: bigint, b: bigint): bigint => %raw("a << b")
    let shift_right = (a: bigint, b: bigint): bigint => %raw("a >> b")
    let logor = (a: bigint, b: bigint): bigint => %raw("a | b")
    let logand = (a: bigint, b: bigint): bigint => %raw("a & b")
    @@warning("+27")
  }
}
