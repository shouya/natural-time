defmodule NaturalTimeTest do
  use ExUnit.Case
  import NaturalTime
  doctest NaturalTime

  # 2019-06-02 is a Sunday
  @now Timex.parse!("2019-06-02T01:04:21+08:00", "{ISO:Extended}")

  test "greets the world" do
    assert_parse("at 10pm", "2019-06-02T22:00:00+08:00")
    assert_parse("at 11pm", "2019-06-02T23:00:00+08:00")
    assert_parse("at 12 midnight", "2019-06-02T00:00:00+08:00")
    assert_parse("tomorrow 12 morning", "2019-06-03T00:00:00+08:00")
    assert_parse("tomorrow 23", "2019-06-03T23:00:00+08:00")
    assert_parse("1:30 p.m.", "2019-06-02T13:30:00+08:00")
    assert_parse("Monday 1:30 p.m.", "2019-06-03T13:30:00+08:00")
    assert_parse("1:30 p.m. on Monday", "2019-06-03T13:30:00+08:00")
    assert_parse("1:30 p.m. on next Monday", "2019-06-03T13:30:00+08:00")
    assert_parse("1:30 p.m. on next next Monday", "2019-06-10T13:30:00+08:00")
  end

  def assert_parse(nat, actual) do
    if parse(nat, @now) == Timex.parse!(actual, "{ISO:Extended}") do
      :ok
    else
      IO.puts(nat)
      assert parse(nat, @now) == Timex.parse!(actual, "{ISO:Extended}")
    end
  end
end
