# star_scan

A parallel implementation of the scan function with a `O(log n)` runtime.

## Example:

```gleam
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

  let parallel_scan_time =
    stopwatch.stopwatch(
      fn() {
        scan.parallel_scan(very_large_list, expensive_combine_fn, 0)
        |> result.lazy_unwrap(fn() { [] })
        Nil
      },
      stopwatch.Millisecond,
    )
  io.println(
    "Parallel scan done in " <> int.to_string(parallel_scan_time) <> " ms",
  )
}
```


## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```


## TODO's

Make this a package, then I can have all this stuff:
[![Package Version](https://img.shields.io/hexpm/v/star_scan)](https://hex.pm/packages/star_scan)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/star_scan/)
```sh
gleam add star_scan@1
```
```gleam
import star_scan

pub fn main() {
  let errors = [5, 1, 10, 6]
  let running_total_errors = star_scan(errors)
  io.println("Running total:")
  io.println(string.join(running_total_errors), ", ")
  // -> 5, 6, 16, 22
}
```
