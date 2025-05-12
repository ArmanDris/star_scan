# star_scan

A multi-threaded scanning function implemented using the [BEAM VM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)) with [Gleam](https://gleam.run/).

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

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
