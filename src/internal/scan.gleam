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
  Ok(list)
}

// This function will either:
//   - Spawn a new version of itself to handle the other half of its list
//   - Dance with sub_list_scanner to calculate and arrage the scan of its halves
pub fn list_breaker(
  l: List(a),
  combine_fn: fn(a, a) -> a,
  start_index: Int,
) -> Result(List(a), String) {
  let l_len = list.length(l)
  case l_len > 2 {
    True -> {
      let #(left_half, right_half) = list.split(l, l_len / 2)
      use left_scan <- result.try(list_breaker(
        left_half,
        combine_fn,
        start_index,
      ))
      use right_scan <- result.try(list_breaker(
        right_half,
        combine_fn,
        start_index + l_len / 2,
      ))
      Ok(list.append(left_scan, right_scan))
    }
    False -> {
      let prev_total_channel = process.new_subject()
      let scan_total_channel = process.new_subject()
      let subject_to_receive_child_subject = process.new_subject()
      sub_list_scanner(
        l,
        combine_fn,
        prev_total_channel,
        scan_total_channel,
        subject_to_receive_child_subject,
      )
      use child_subject <- result.try(
        process.receive(subject_to_receive_child_subject, 1000)
        |> result.map_error(fn(_) {
          "Did not receive subject from child process"
        }),
      )
      Ok([])
    }
  }
}

// This function will dance with its caller to
// calculate the scan of its list while facilitating
// a larger parallel implementation. Its communication
// is:
//   1. Send a subject to the parent
//   2. Send the reduce of its part of the list to the parent
//   3. Receive the reduce of all the element before its segement in the list
//   4. Use the reduce of all previous elements to calculate the scan of its
//      part of the list, then sends the scan to the parent
pub fn sub_list_scanner(
  list: List(a),
  combine_fn: fn(a, a) -> a,
  parent_val_ch: process.Subject(Result(a, String)),
  parent_list_ch: process.Subject(Result(List(a), String)),
  send_subject_throuh: process.Subject(Subject(Result(a, Nil))),
) -> Nil {
  // Step 1: Send a subject to parent so they
  //         can receive values from us
  let my_subject = process.new_subject()
  process.send(send_subject_throuh, my_subject)

  // Step 2: Calculate reduce of current section and
  //         send it to the parent
  let reduce_section = hybrid_reduce(list, combine_fn)
  process.send(parent_val_ch, reduce_section)

  // Step 3: Receive prev_total from parent
  let res =
    process.receive(my_subject, 10_000)
    |> result.flatten()

  // Step 4: Calculate scan for this segment with prev_total from parent
  let scan_section = case res {
    Ok(prev_total) -> Ok(list.scan(list, prev_total, combine_fn))
    Error(Nil) -> Error("Some error receiving prev_result")
  }

  // Step 5: Send cumulative scan to parent
  process.send(parent_list_ch, scan_section)
  Nil
}
