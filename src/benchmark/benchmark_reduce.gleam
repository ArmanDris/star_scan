import gleam/float
import gleam/int
import gleam/io
import gleam/result
import internal/reduce
import internal/stopwatch

pub fn benchmark_reduce() {
  // Comapres the runtime of a sequential and parallel implementation 
  // of reduce
  io.println("Benchmarking reduce on a list of 100 million integers")
  let very_large_list = reduce.generate_list(100_000_000)

  // Define a complex combine fn for benchmarking
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
  io.println("Sequential reduce done in " <> int.to_string(time_taken) <> " ms")
  let hyrbid_reduce_time_taken =
    stopwatch.stopwatch(
      fn() {
        let _ = reduce.hybrid_reduce(very_large_list, combine_fn)
        Nil
      },
      stopwatch.Millisecond,
    )
  io.println(
    "Parallel reduce done in "
    <> int.to_string(hyrbid_reduce_time_taken)
    <> " ms",
  )
}
