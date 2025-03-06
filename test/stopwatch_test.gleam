import gleam/erlang/process
import gleeunit
import gleeunit/should
import internal/stopwatch

pub fn main() {
  gleeunit.main()
}

pub fn stopwatch_test() {
  let time_sleep_100 =
    stopwatch.stopwatch(
      fn() {
        process.sleep(100)
        Nil
      },
      stopwatch.Millisecond,
    )
  let within_5_ms = time_sleep_100 > 95 && time_sleep_100 < 105
  should.be_true(within_5_ms)

  let time_sleep_10 =
    stopwatch.stopwatch(
      fn() {
        process.sleep(10)
        Nil
      },
      stopwatch.Millisecond,
    )
  let time_sleep_10_within_5_ms = time_sleep_10 > 5 && time_sleep_10 < 15
  should.be_true(time_sleep_10_within_5_ms)
}
