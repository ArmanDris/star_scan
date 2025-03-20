import benchmark/benchmark_reduce
import gleam/int
import gleam/io
import internal/reduce
import internal/scan
import internal/stopwatch

pub fn main() {
  let very_large_list = reduce.generate_list(500)
  // let combine_fn = fn(a, b) {
  //   int.power(a, int.to_float(b))
  //   |> result.lazy_unwrap(fn() { 1.0 })
  //   |> float.logarithm()
  //   |> result.lazy_unwrap(fn() { 1.0 })
  //   |> fn(e_base_log) {
  //     e_base_log
  //     /. result.lazy_unwrap(float.logarithm(int.to_float(b)), fn() { 1.0 })
  //   }
  //   |> float.round()
  // }
  let sequential_scan_time =
    stopwatch.stopwatch(
      fn() {
        scan.sequential_scan(very_large_list, int.add, 0)
        Nil
      },
      stopwatch.Millisecond,
    )
  io.println(
    "Sequential scan done in " <> int.to_string(sequential_scan_time) <> " ms",
  )
}
