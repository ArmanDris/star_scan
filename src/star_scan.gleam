import gleam/int
import gleam/io
import internal/reduce
import internal/stopwatch

pub fn main() {
  let very_large_list = reduce.generate_array(100_000_000)
  // let one_hundred_k_list = reduce.generate_list(100_000)
  // let one_hundred_list = reduce.generate_list(100)
  let time_taken =
    stopwatch.stopwatch(
      fn() {
        let _ = reduce.sequential_reduce(very_large_list, int.add)
        Nil
      },
      stopwatch.Millisecond,
    )
  io.println("Reduce time taken " <> int.to_string(time_taken) <> " ms")
  let par_time_taken =
    stopwatch.stopwatch(
      fn() {
        let _ = reduce.parallel_reduce(very_large_list, fn(a, b) { a + b })
        Nil
      },
      stopwatch.Millisecond,
    )
  io.println("Par time taken " <> int.to_string(par_time_taken) <> " ms")
}
