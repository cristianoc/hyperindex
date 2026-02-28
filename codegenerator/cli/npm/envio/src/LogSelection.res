exception MissingRequiredTopic0

let hasFilters = ({topic1, topic2, topic3}: Internal.topicSelection) => {
  [topic1, topic2, topic3]->Array.find(topic => !Utils.Array.isEmpty(topic))->Belt.Option.isSome
}

/**
For a group of topic selections, if multiple only use topic0, then they can be compressed into one
selection combining the topic0s
*/
let compressTopicSelections = (topicSelections: array<Internal.topicSelection>) => {
  let topic0sOfSelectionsWithoutFilters = []

  let selectionsWithFilters = []

  topicSelections->Belt.Array.forEach(selection => {
    if selection->hasFilters {
      selectionsWithFilters->Array.push(selection)->ignore
    } else {
      selection.topic0->Belt.Array.forEach(topic0 => {
        topic0sOfSelectionsWithoutFilters->Array.push(topic0)->ignore
      })
    }
  })

  switch topic0sOfSelectionsWithoutFilters {
  | [] => selectionsWithFilters
  | topic0 =>
    let selectionWithoutFilters = {
      Internal.topic0,
      topic1: [],
      topic2: [],
      topic3: [],
    }
    Belt.Array.concat([selectionWithoutFilters], selectionsWithFilters)
  }
}

type t = {
  addresses: array<Address.t>,
  topicSelections: array<Internal.topicSelection>,
}

let make = (~addresses, ~topicSelections) => {
  let topicSelections = compressTopicSelections(topicSelections)
  {addresses, topicSelections}
}

type parsedEventFilters = {
  getEventFiltersOrThrow: ChainMap.Chain.t => Internal.eventFilters,
  dependsOnAddresses: bool,
}
