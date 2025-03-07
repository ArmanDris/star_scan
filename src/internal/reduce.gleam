import gleam/list
import gleam/otp/task
import gleam/result
import prng/random
import prng/seed

pub fn sequential_reduce(
  // Sequential implementation of a
  // reduce function
  // Params:
  //  - list the list to operate on
  //  - combine_fn the function to combine
  //               values with
  list: List(a),
  combine_fn: fn(a, a) -> a,
) -> Result(a, String) {
  case list {
    [] -> Error("Should have a list with at least one element")
    [a] -> Ok(a)
    [x, ..rest] -> Ok(sequential_reduce_helper(rest, combine_fn, x))
  }
}

fn sequential_reduce_helper(
  list: List(a),
  combine_fn: fn(a, a) -> a,
  accumulated_value: a,
) -> a {
  case list {
    [] -> accumulated_value
    [a, ..rest] ->
      sequential_reduce_helper(
        rest,
        combine_fn,
        combine_fn(a, accumulated_value),
      )
  }
}

pub fn parallel_reduce(
  list: List(a),
  combine_fn: fn(a, a) -> a,
) -> Result(a, String) {
  helper_parallel_reduce(list, combine_fn)
}

fn helper_parallel_reduce(
  list: List(a),
  combine_fn: fn(a, a) -> a,
) -> Result(a, String) {
  // Splits into two processes, each with half the list, until the
  // list is smaller than max_segment_size.
  case list {
    [] -> Error("Cannot reduce on an empty list")
    [a] -> Ok(a)
    [_, _, ..] -> {
      // Split in two
      let #(first_half, second_half) = list.split(list, list.length(list) / 2)
      let task_one =
        task.async(fn() { helper_parallel_reduce(first_half, combine_fn) })
      let task_two =
        task.async(fn() { helper_parallel_reduce(second_half, combine_fn) })
      let #(r_one, r_two) = task.try_await2(task_one, task_two, 1000)
      use r_one_p <- result.try(
        r_one
        |> result.map_error(fn(_) {
          "Reduce hit timeout before result was received"
        }),
      )
      use r_one_p_p <- result.try(r_one_p)
      use r_two_p <- result.try(
        r_two
        |> result.map_error(fn(_) {
          "Reduce hit timeour before result was recieved"
        }),
      )
      use r_two_p_p <- result.try(r_two_p)
      Ok(combine_fn(r_one_p_p, r_two_p_p))
    }
  }
  // case list_len > max_segment_size {
  //   True -> {
  //     // Split in two
  //     let #(first_half, second_half) = list.split(list, list_len / 2)
  //     let task_one =
  //       task.async(fn() {
  //         helper_parallel_reduce(first_half, list_len / 2, combine_fn)
  //       })
  //     let task_two =
  //       task.async(fn() {
  //         helper_parallel_reduce(second_half, list_len / 2, combine_fn)
  //       })
  //     let #(r_one, r_two) = task.try_await2(task_one, task_two, 1000)
  //     use r_one_p <- result.try(
  //       r_one
  //       |> result.map_error(fn(_) {
  //         "Reduce hit timeout before result was received"
  //       }),
  //     )
  //     use r_one_p_p <- result.try(r_one_p)
  //     use r_two_p <- result.try(
  //       r_two
  //       |> result.map_error(fn(_) {
  //         "Reduce hit timeour before result was recieved"
  //       }),
  //     )
  //     use r_two_p_p <- result.try(r_two_p)
  //     Ok(combine_fn(r_one_p_p, r_two_p_p))
  //   }
  //   False -> {
  //     sequential_reduce(list, combine_fn)
  //   }
  // }
}

pub fn hybrid_reduce(
  list: List(a),
  combine_fn: fn(a, a) -> a,
) -> Result(a, String) {
  helper_hybrid_reduce(list, combine_fn)
}

fn helper_hybrid_reduce(
  list: List(a),
  combine_fn: fn(a, a) -> a,
) -> Result(a, String) {
  let max_segment_size = 10_000
  let list_len = list.length(list) / 2
  case list_len > max_segment_size {
    True -> {
      // Split in two
      let #(first_half, second_half) = list.split(list, list_len / 2)
      let task_one =
        task.async(fn() { helper_hybrid_reduce(first_half, combine_fn) })
      let task_two =
        task.async(fn() { helper_hybrid_reduce(second_half, combine_fn) })
      let #(r_one, r_two) = task.try_await2(task_one, task_two, 1000)
      use r_one_p <- result.try(
        r_one
        |> result.map_error(fn(_) {
          "Reduce hit timeout before result was received"
        }),
      )
      use r_one_p_p <- result.try(r_one_p)
      use r_two_p <- result.try(
        r_two
        |> result.map_error(fn(_) {
          "Reduce hit timeour before result was recieved"
        }),
      )
      use r_two_p_p <- result.try(r_two_p)
      Ok(combine_fn(r_one_p_p, r_two_p_p))
    }
    False -> {
      sequential_reduce(list, combine_fn)
    }
  }
}

pub fn generate_list(n: Int) -> List(Int) {
  // Generates a list of n integers from 0 to 100
  let seed = seed.new(0)
  let generator: random.Generator(Int) = random.int(0, 100)
  let num_generator = random.fixed_size_list(generator, n)
  let #(first_roll, _new_seed) = num_generator |> random.step(seed)
  first_roll
}
