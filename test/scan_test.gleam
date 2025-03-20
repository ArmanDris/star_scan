import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/otp/actor
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import internal/scan

pub fn main() {
  gleeunit.main()
}

pub fn sequential_reduce_test() {
  scan.sequential_scan(["a"], string.append, "")
  |> should.equal(["a"])
  scan.sequential_scan([123, 45, 4], int.add, 0)
  |> should.equal([123, 168, 172])
}

pub fn scan_actor_test() {
  // Our scan actor should correctly scan segements
  // of this list when given the correct inputs
  let ten_list = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  // Test 1. Scan whole list
  let state_one = scan.ScanActorState(ten_list, int.add)
  let assert Ok(actor_one) = actor.start(state_one, scan.scan_actor)
  process.try_call(actor_one, scan.RunReduce, 1000)
  |> result.map_error(fn(_) { "Error calling reduce on an actor" })
  |> result.flatten
  |> should.equal(Ok(45))

  process.try_call(actor_one, fn(s) { scan.RunScan(0, s) }, 1000)
  |> result.map_error(fn(_) { "Error calling reduce on an actor" })
  |> result.flatten
  |> should.equal(Ok([0, 1, 3, 6, 10, 15, 21, 28, 36, 45]))

  // Test 2. Scan on second half of list
  let #(_, five_to_nine) = list.split(ten_list, 5)
  let state_two = scan.ScanActorState(five_to_nine, int.add)
  let assert Ok(actor_two) = actor.start(state_two, scan.scan_actor)
  process.try_call(actor_two, scan.RunReduce, 1000)
  |> result.map_error(fn(_) { "Error calling reduce on an actor" })
  |> result.flatten
  |> should.equal(Ok(35))
  process.try_call(actor_two, fn(s) { scan.RunScan(10, s) }, 1000)
  |> result.map_error(fn(_) { "Error calling reduce on an actor" })
  |> result.flatten
  |> should.equal(Ok([15, 21, 28, 36, 45]))
}
