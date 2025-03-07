import gleam/float
import gleam/int
import gleam/io
import gleam/result
import internal/reduce
import internal/stopwatch

pub fn main() {
  let very_large_list = reduce.generate_list(100_000_000)
  let combine_fn = fn(a, b) {
    int.power(a, int.to_float(b))
    |> result.lazy_unwrap(fn() { 1.0 })
    |> float.logarithm()
    |> result.lazy_unwrap(fn() { 1.0 })
    |> fn(e_base_log) {
      e_base_log
      /. result.lazy_unwrap(float.logarithm(int.to_float(b)), fn() { 1.0 })
    }
    |> float.round()
  }
  let time_taken =
    stopwatch.stopwatch(
      fn() {
        let _ = reduce.sequential_reduce(very_large_list, combine_fn)
        Nil
      },
      stopwatch.Millisecond,
    )
  io.println("Reduce time taken " <> int.to_string(time_taken) <> " ms")
  // let par_time_taken =
  //   stopwatch.stopwatch(
  //     fn() {
  //       let _ = reduce.parallel_reduce(very_large_list, combine_fn)
  //       Nil
  //     },
  //     stopwatch.Millisecond,
  //   )
  // io.println("Par time taken " <> int.to_string(par_time_taken) <> " ms")
  let hyrbid_reduce_time_taken =
    stopwatch.stopwatch(
      fn() {
        let _ = reduce.hybrid_reduce(very_large_list, combine_fn)
        Nil
      },
      stopwatch.Millisecond,
    )
  io.println(
    "Hybrid time taken " <> int.to_string(hyrbid_reduce_time_taken) <> " ms",
  )
}
