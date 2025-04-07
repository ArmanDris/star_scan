import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/result
import internal/reduce.{hybrid_reduce}

pub fn sequential_scan(
  list: List(a),
  combine_fn: fn(a, a) -> a,
  starting_value: a,
) -> List(a) {
  helper_sequential_scan(list, combine_fn, starting_value, [])
}

fn helper_sequential_scan(
  list: List(a),
  combine_fn: fn(a, a) -> a,
  prev_value: a,
  accumulator: List(a),
) -> List(a) {
  case list {
    [] -> list.reverse(accumulator)
    [next, ..rest] -> {
      // Call combine fn on next in list and
      // prev in accumulator
      let next_val = combine_fn(next, prev_value)
      helper_sequential_scan(rest, combine_fn, next_val, [
        next_val,
        ..accumulator
      ])
    }
  }
}

pub fn parallel_scan(
  list: List(a),
  combine_fn: fn(a, a) -> a,
  identity_element: a,
) -> Result(List(a), String) {
  let parent_subject = process.new_subject()
  let actor_state =
    ScanActorState(list, combine_fn, parent_subject, identity_element)
  use actor <- result.try(
    actor.start(actor_state, scan_actor)
    |> result.map_error(fn(_) { "Error starting actor" }),
  )

  use prev_value <- result.try(
    process.try_call(actor, RunReduce, 1000)
    |> result.map_error(fn(_) {
      "Error receiving reduce from actor. Part of parallel scan"
    })
    |> result.flatten,
  )

  process.try_call(actor, fn(s) { RunScan(prev_value, s) }, 2000)
  |> result.map_error(fn(_) { "Error receiving scan result from actor" })
  |> result.flatten
}

// The scan_actor will need to first run a reduce and send it to the parent,
// it will then need to run a scan using `prev_value` from the parent and
// then it will need to send the scan result to the parent
pub type Message(a) {
  RunReduce(reply_with: Subject(Result(a, String)))
  RunScan(prev_total: a, reply_with: Subject(Result(List(a), String)))
}

// Our scan actor should be initialized with a list and a combine
// function. These are the same for both its reduce and scan operation
pub type ScanActorState(a) {
  ScanActorState(
    list: List(a),
    combine_fn: fn(a, a) -> a,
    send_total_to: Subject(a),
    identity_element: a,
  )
}

pub fn scan_actor(
  message: Message(a),
  state: ScanActorState(a),
) -> actor.Next(Message(a), ScanActorState(a)) {
  let max_list_size = 2
  case message {
    // We already have an efficient, parallel implementation of reduce
    // so we just call that here
    RunReduce(reply_with) -> {
      process.send(reply_with, hybrid_reduce(state.list, state.combine_fn))
      actor.continue(state)
    }
    // When we receive this message we will recursively split the list
    // in two and give each half to a scan_actor.
    RunScan(prev_total, reply_with) -> {
      let list_len = list.length(state.list)
      let result = case list_len <= 2 {
        True -> {
          Ok(list.scan(state.list, prev_total, state.combine_fn))
        }
        False -> {
          let #(left_half, right_half) = list.split(state.list, list_len / 2)

          let this_actor_subject = process.new_subject()

          let state_left =
            ScanActorState(
              left_half,
              state.combine_fn,
              this_actor_subject,
              state.identity_element,
            )
          let state_right =
            ScanActorState(
              right_half,
              state.combine_fn,
              this_actor_subject,
              state.identity_element,
            )
          use actor_left <- result.try(
            actor.start(state_left, scan_actor)
            |> result.map_error(fn(_) {
              "Error starting child actor in scan_reduce"
            }),
          )
          use actor_right <- result.try(
            actor.start(state_right, scan_actor)
            |> result.map_error(fn(_) {
              "Error starting child actor in scan_reduce"
            }),
          )
          use reduce_left <- result.try(process.call(
            actor_left,
            RunReduce,
            1000,
          ))
          use reduce_right <- result.try(process.call(
            actor_right,
            RunReduce,
            1000,
          ))

          process.send(state.send_total_to, reduce_right)

          use left_node_prev_total <- result.try(
            process.receive(state.send_total_to, 1000)
            |> result.try_recover(fn(_) { Ok(state.identity_element) }),
          )

          use scan_left <- result.try(process.call(
            actor_left,
            fn(s) { RunScan(left_node_prev_total, s) },
            1000,
          ))
          use scan_right <- result.try(process.call(
            actor_right,
            fn(s) { RunScan(reduce_left, s) },
            1000,
          ))

          Ok(list.append(scan_left, scan_right))
        }
      }
      process.send(reply_with, result)
      actor.Stop(process.Normal)
    }
  }
}
