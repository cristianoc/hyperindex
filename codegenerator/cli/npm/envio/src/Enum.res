// Graphql Enum Type Variants
type enum<'a> = {
  name: string,
  schema: S.t<'a>,
}

let make = (~name, ~variants) => {
  name,
  schema: S.enum(variants),
}

module type S = {
  type t
  let enum: enum<t>
}
