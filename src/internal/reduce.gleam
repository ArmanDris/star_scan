import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/task
import gleam/result
import glearray
import internal/stopwatch
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
  let len_list = list.length(list)
  use num_workers <- result.try(
    int.square_root(len_list)
    |> result.map(fn(n) { float.round(n) })
    |> result.map_error(fn(_) { "Error while doing log calculation" }),
  )
  let split_list = split_lists(list, len_list / num_workers, [])
  let split_list_time =
    stopwatch.stopwatch(
      fn() {
        split_lists(list, len_list / num_workers, [])
        Nil
      },
      stopwatch.Millisecond,
    )
  io.println("Split lists in " <> int.to_string(split_list_time))
  helper_parallel_reduce(split_list, combine_fn)
}

pub fn split_lists(
  list: List(a),
  partition_size: Int,
  accumulator: List(List(a)),
) -> List(List(a)) {
  // Splits list into partition_size'd partitions
  // accumulator should start as an empty array []
  case list {
    [] -> accumulator
    [_, ..] -> {
      let #(new_part, rest) = list.split(list, partition_size)
      split_lists(rest, partition_size, list.prepend(accumulator, new_part))
    }
  }
}

fn helper_parallel_reduce(lists: List(List(a)), combine_fn: fn(a, a) -> a) {
  // This is a list with an ugly nested result
  // List(Result(Result, String), String)
  // The outer result is in case a task times out and the inner result
  // is in case a sequential reduce fails
  let list_of_task_and_reduce_results =
    lists
    |> list.map(fn(l) { task.async(fn() { sequential_reduce(l, combine_fn) }) })
    |> task.try_await_all(1000)
    |> result.all()
    |> result.map_error(fn(_) {
      "Hit timeout before receiving all tasks responses"
    })

  use task_results <- result.try(list_of_task_and_reduce_results)
  // This will unpack the sequential reduce result, returning early if there was
  // a reduce timeout
  use task_values <- result.try(result.all(task_results))

  // We finally combine the values our tasks gave us
  sequential_reduce(task_values, combine_fn)
}

pub fn generate_array(n: Int) -> List(Int) {
  // Generates a list of n integers from 0 to 100
  let seed = seed.new(0)
  let generator: random.Generator(Int) = random.int(0, 100)
  let num_generator = random.fixed_size_list(generator, n)
  let #(first_roll, _new_seed) = num_generator |> random.step(seed)
  first_roll
}
