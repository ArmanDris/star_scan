import gleam/int
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import internal/reduce

pub fn main() {
  gleeunit.main()
}

pub fn split_list_test() {
  reduce.split_lists([5, 10, 4, 8, 5, 4], 2, [])
  |> should.equal([[5, 4], [4, 8], [5, 10]])
  reduce.split_lists([], 5, [])
  |> should.equal([])
  reduce.split_lists([7, 1, 8, 23, 76, 2, 8, 0], 5, [])
  |> should.equal([[2, 8, 0], [7, 1, 8, 23, 76]])
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
