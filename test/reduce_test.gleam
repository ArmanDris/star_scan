import gleam/int
import gleam/string
import gleeunit
import gleeunit/should
import internal/reduce

pub fn main() {
  gleeunit.main()
}

pub fn sequential_reduce_test() {
  reduce.sequential_reduce([], int.add)
  |> should.be_error()
  reduce.sequential_reduce(["a"], string.append)
  |> should.equal(Ok("a"))
  reduce.sequential_reduce([123, 45, 4], int.add)
  |> should.equal(Ok(172))
}

pub fn parallel_reduce_test() {
  reduce.parallel_reduce([], int.add)
  |> should.be_error()
  reduce.parallel_reduce(["a"], string.append)
  |> should.equal(Ok("a"))
  reduce.parallel_reduce([123, 45, 4], int.add)
  |> should.equal(Ok(172))
}
