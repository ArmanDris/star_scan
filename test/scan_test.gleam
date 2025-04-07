import gleam/erlang/process
import gleam/int
import gleam/io
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

pub fn sub_list_scanner_single_test() {
  let nums = [1, 2, 3, 4, 5]

  let left_val_ch = process.new_subject()
  let left_list_ch = process.new_subject()
  let left_receive_subject_through = process.new_subject()

  process.start(
    fn() {
      scan.sub_list_scanner(
        nums,
        int.add,
        left_val_ch,
        left_list_ch,
        left_receive_subject_through,
      )
    },
    False,
  )
  use child_subject <- result.try(
    process.receive(left_receive_subject_through, 10_000)
    |> result.map_error(fn(_) {
      io.println("Timeout while trying to receive child's subject")
      Nil
    }),
  )
  process.send(child_subject, Ok(0))
  let left_total =
    process.receive(left_val_ch, 10_000)
    |> result.map_error(fn(_) { "Timeout while waiting for child prev_total" })
    |> result.flatten()
  should.equal(left_total, Ok(15))
  let scan_result =
    process.receive(left_list_ch, 10_000)
    |> result.map_error(fn(_) { "Timeout while waiting for scan_result" })
    |> result.flatten()
  should.equal(Ok([1, 3, 6, 10, 15]), scan_result)
  Ok(Nil)
}

pub fn sub_list_scanner_double_test() -> Result(Nil, String) {
  let #(left_half, right_half) = list.split([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 5)

  let left_val_ch = process.new_subject()
  let left_list_ch = process.new_subject()
  let left_receive_subject_through = process.new_subject()

  let right_val_ch = process.new_subject()
  let right_list_ch = process.new_subject()
  let right_receive_subject_through = process.new_subject()

  // Start left and right process
  process.start(
    fn() {
      scan.sub_list_scanner(
        left_half,
        int.add,
        left_val_ch,
        left_list_ch,
        left_receive_subject_through,
      )
    },
    True,
  )
  process.start(
    fn() {
      scan.sub_list_scanner(
        right_half,
        int.add,
        right_val_ch,
        right_list_ch,
        right_receive_subject_through,
      )
    },
    True,
  )

  // Receive both their subjects
  use left_subject <- result.try(
    process.receive(left_receive_subject_through, 10_000)
    |> result.map_error(fn(_) { "Did not receive left subject" }),
  )
  use right_subject <- result.try(
    process.receive(right_receive_subject_through, 10_000)
    |> result.map_error(fn(_) { "Did not receive right subject" }),
  )

  use left_total <- result.try(
    process.receive(left_val_ch, 10_000)
    |> result.map_error(fn(_) { "Timeout while waiting for left total" })
    |> result.flatten(),
  )

  // Send each child their prev_total
  process.send(left_subject, Ok(0))
  use left_result <- result.try(
    process.receive(left_list_ch, 10_000)
    |> result.map_error(fn(_) { "Timeout while waiting for left scan_result" })
    |> result.flatten(),
  )
  should.equal([1, 3, 6, 10, 15], left_result)

  process.send(right_subject, Ok(left_total))
  use right_result <- result.try(
    process.receive(right_list_ch, 10_000)
    |> result.map_error(fn(_) { "Timeout while waiting for right_scan_result" })
    |> result.flatten(),
  )
  should.equal([21, 28, 36, 45, 55], right_result)

  let final_result = list.append(left_result, right_result)
  io.debug(final_result)
  Ok(Nil)
}
