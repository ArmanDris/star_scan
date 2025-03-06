pub type TimeUnit {
  Second
  Millisecond
  Microsecond
  Nanosecond
  Native
}

// Returns a time unit. The returned value
// has no inherit meaning and must be converted
// to a known value using convert_time_unit/3. 
// I know this sounds dumb but its how erlang
// works and erlang was written in the 80's so
// cut it some slack.
@external(erlang, "erlang", "monotonic_time")
pub fn get_time_unit() -> Int

@external(erlang, "erlang", "convert_time_unit")
pub fn convert_time_unit(
  time: Int,
  from_unit: TimeUnit,
  to_unit: TimeUnit,
) -> Int

pub fn stopwatch(a: fn() -> Nil, units: TimeUnit) -> Int {
  // Runs the function and returns the
  // runtime in seconds
  let start_time = get_time_unit()
  a()
  let end_time = get_time_unit()
  convert_time_unit({ end_time - start_time }, Native, units)
}
