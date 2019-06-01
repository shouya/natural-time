defmodule NaturalTimeTest do
  use ExUnit.Case
  import NaturalTime
  doctest NaturalTime

  @now Timex.parse!("2019-06-02T01:04:21+08:00", "{ISO:Extended}")

  test "greets the world" do
    IO.inspect(parse("at 10pm"))
  end
end
