import gleam/float
import gleam/int
import gleam/io
import gleam/result
import internal/reduce
import internal/scan
import internal/stopwatch

pub fn main() {
  let very_large_list = reduce.generate_list(20_000)

  let expensive_combine_fn = fn(a, b) {
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

  let sequential_scan_time =
    stopwatch.stopwatch(
      fn() {
        scan.sequential_scan(very_large_list, expensive_combine_fn, 0)
        Nil
      },
      stopwatch.Millisecond,
    )
  io.println(
    "Sequential scan done in " <> int.to_string(sequential_scan_time) <> " ms",
  )

  let parallel_scan_time =
    stopwatch.stopwatch(
      fn() {
        scan.parallel_scan(very_large_list, expensive_combine_fn)
        |> result.lazy_unwrap(fn() { [] })
        Nil
      },
      stopwatch.Millisecond,
    )
  io.println(
    "Parallel scan done in " <> int.to_string(parallel_scan_time) <> " ms",
  )
}
