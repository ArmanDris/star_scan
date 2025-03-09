import gleam/list

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
    [] -> accumulator
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
