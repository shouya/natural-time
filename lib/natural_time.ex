defmodule NaturalTime do
  import NimbleParsec

  ws = string(" ") |> repeat() |> ignore()
  int2 = integer(min: 1, max: 2)

  preposition =
    optional(
      choice([
        string("in the"),
        string("on the"),
        string("at the"),
        string("in"),
        string("on"),
        string("at")
      ])
    )

  with_optional_prep = fn p ->
    concat(ignore(replace(preposition |> concat(ws), "")), p)
  end

  ampm =
    with_optional_prep.(
      choice([
        string("am"),
        string("pm"),
        replace(string("a.m."), "am"),
        replace(string("p.m."), "pm"),
        replace(string("midnight"), "am"),
        replace(string("morning"), "am"),
        replace(string("noon"), "pm"),
        replace(string("afternoon"), "pm"),
        replace(string("evening"), "pm"),
        replace(string("night"), "pm")
      ])
    )

  rel_day =
    choice([
      string("today"),
      string("tomorrow"),
      replace(string("tmr"), "tomorrow")
    ])

  weekday =
    with_optional_prep.(
      choice([
        string("monday"),
        string("tuesday"),
        string("wednesday"),
        string("thursday"),
        string("friday"),
        string("saturday"),
        string("sunday"),
        replace(string("mon"), "monday"),
        replace(string("tue"), "tuesday"),
        replace(string("wed"), "wednesday"),
        replace(string("thu"), "thursday"),
        replace(string("fri"), "friday"),
        replace(string("sat"), "saturday"),
        replace(string("sun"), "sunday")
      ])
    )

  rel_adv = choice([string("this"), string("next")])

  time =
    with_optional_prep.(
      choice([
        int2
        |> concat(ignore(string(":")))
        |> concat(int2)
        |> concat(ws)
        |> concat(ampm)
        |> tag(:hm_ap),
        int2 |> concat(ws) |> concat(ampm) |> tag(:h_ap),
        int2 |> concat(ignore(string(":"))) |> concat(int2) |> tag(:hm),
        int2 |> tag(:h)
      ])
    )

  day =
    choice([
      rel_day |> tag(:rel_day),
      rel_adv |> concat(ws) |> concat(weekday) |> tag(:rel_weekday),
      weekday |> tag(:weekday)
    ])

  defparsec(
    :datetime,
    choice([
      day |> concat(ws) |> concat(time) |> tag(:day_time),
      time |> concat(ws) |> concat(day) |> tag(:time_day),
      time |> tag(:time_only)
    ])
  )

  def parse(str, rel \\ Timex.now()) do
    str = str |> String.downcase() |> String.trim()

    case datetime(str) do
      {:ok, result, "", _, _, _} ->
        parse_datetime(rel, result)

      _ ->
        nil
    end
  end

  defp parse_datetime(now, day_time: [day, time]) do
    date = parse_day(now, [day])
    time = parse_time(now, [time])
    Timex.set(now, date: date, time: time)
  end

  defp parse_datetime(now, time_day: [time, day]) do
    date = parse_day(now, [day])
    time = parse_time(now, [time])
    Timex.set(now, date: date, time: time)
  end

  defp parse_datetime(now, time_only: [time]) do
    time = parse_time(now, [time])
    Timex.set(now, time: time)
  end

  defp parse_day(now, rel_day: ["today"]) do
    Timex.to_date(now)
  end

  defp parse_day(now, rel_day: ["tomorrow"]) do
    now |> Timex.to_date() |> Timex.shift(days: 1)
  end

  defp parse_day(now, weekday: [weekday]) do
    parse_day(now, rel_weekday: ["", weekday])
  end

  defp parse_day(now, rel_weekday: [adv, weekday]) do
    curr_day = Timex.weekday(now)
    target_day = Timex.day_to_num(weekday)

    offset =
      case adv do
        "" -> rem(target_day - curr_day + 7, 7)
        "this" -> target_day - curr_day
        "next" -> target_day + 7 - curr_day
      end

    now
    |> Timex.to_date()
    |> Timex.shift(days: offset)
  end

  defp parse_time(now, h_ap: [h, ap]) do
    parse_time(now, hm_ap: [h, 0, ap])
  end

  defp parse_time(now, hm_ap: [h, m, "am"]) do
    now
    |> Timex.set(hour: rem(h, 12), minute: m, second: 0)
    |> to_time()
  end

  defp parse_time(now, hm_ap: [h, m, "pm"]) do
    now
    |> Timex.set(hour: rem(h, 12) + 12, minute: m, second: 0)
    |> to_time()
  end

  defp parse_time(now, hm: [h, m]) do
    now
    |> Timex.set(hour: h, minute: m, second: 0)
    |> to_time()
  end

  defp parse_time(now, h: [h]) do
    now
    |> Timex.set(hour: h, minute: 0, second: 0)
    |> to_time()
  end

  defp to_time(datetime) do
    {datetime.hour, datetime.minute, datetime.second}
  end
end
