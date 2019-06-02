defmodule NaturalTime do
  @moduledoc """
  Parse natural language time expression
  """

  @type parse_error_t :: :not_found

  @type segment_info_t :: :period | :day | :hour | :minute | :second

  @type datetime_info_t ::
          {:exact, DateTime.t()}
          | {:ambiguous, DateTime.t(), [segment_info_t]}
  @type match_info_t ::
          {begin :: non_neg_integer(), length :: non_neg_integer()}

  @day_name_pat "(?<day>(today|tomorrow|yesterday))"
  @day_offset_pat "(?<day_offset>(this|next))"
  @day_of_week_pat "(?<day_of_week>(monday|tuesday|wednesday|thursday|friday|saturday|sunday))"
  @time_of_day_pat "(?<time_of_day>(morning|noon|afternoon|evening|night|midnight))"
  @period_pat "(?<period>(am|pm|a\\.m\\.|p\\.m\\.|(((at|in) the )?#{@time_of_day_pat})))"
  @time_pat "(?<hr>\\d{1,2})(:(?<min>\\d{1,2}))?\\s*#{@period_pat}"
  @day_pat "(#{@day_name_pat}|(#{@day_offset_pat}|on)\\s+#{@day_of_week_pat})"
  @duration_pat "(?<dur_num>a|\d+)\s*(?<dur_unit>hrs?|hours?|mins?|minutes?)"

  @all_patterns [
    ~r/at #{@time_pat}/i,
    ~r/#{@day_pat}/i,
    ~r/#{@day_pat}( at)?\s+#{@time_pat}/i,
    ~r/(in|after) #{@duration_pat}/i,
    ~r/#{@duration_pat} (from now|later)/i
  ]

  @spec parse(String.t(), DateTime.t()) ::
          {:ok, {datetime_info_t, match_info_t}} | {:error, parse_error_t}
  def parse(input, now \\ Timex.local()) do
    @all_patterns
    |> Stream.map(&Regex.named_captures(&1, input))
    |> Enum.reduce(:not_found, fn
      nil, :not_found -> :not_found
      cap, :not_found -> {:found, cap}
      _, {:found, cap} -> {:found, cap}
    end)
    |> case do
      {:found, cap} -> resolve_capture(cap, now)
      :not_found -> {:error, :not_found}
    end
  end

  defp resolve_capture(captures, now) do
    captures =
      captures
      |> Enum.reject(fn {_k, v} -> v == "" end)
      |> Enum.map(fn {k, v} -> {k, String.downcase(v)} end)
      |> Map.new()

    [:date, :time]
    |> Enum.map(&resolve_capture(captures, &1, now))
    |> combine(now)
  end

  defp resolve_capture(captures, :date, now) do
    [day, day_of_week, day_offset] =
      ~w"day day_of_week day_offset"
      |> Enum.map(&captures[&1])

    cond do
      is_binary(day) ->
        case parse_day(day, now) do
          %{year: _, month: _, day: _} = date -> date
          _ -> nil
        end

      is_binary(day_of_week) ->
        case parse_day_of_week(day_of_week, day_offset, now) do
          %{year: _, month: _, day: _} = date -> date
          _ -> nil
        end

      true ->
        nil
    end
  end

  defp resolve_capture(captures, :time, now) do
    [hour, minute, second] =
      ~w"hr min sec"
      |> Enum.map(fn unit ->
        captures[unit]
        |> case do
          nil -> nil
          s -> Integer.parse(s)
        end
        |> case do
          {n, ""} -> n
          _ -> nil
        end
      end)

    case resolve_period_and_hour(captures["period"], hour) do
      nil -> nil
      hour -> resolve_hms(hour, minute, second)
    end
  end

  defp combine([date, time], now) do
    date = date || %{}
    time = time || %{}
    datetime = Map.merge(date, time) |> Keyword.new()
    Timex.set(now, datetime)
  end

  defp parse_day("today", now) do
    # Consider ambiguity:
    # now=1:00am -> should ask if today or yesterday
    Map.take(now, [:year, :month, :day])
  end

  defp parse_day("tomorrow", now) do
    # Consider ambiguity:
    # now=1:00am -> should ask if today or tomorrow
    now |> Timex.shift(days: 1) |> Map.take([:year, :month, :day])
  end

  defp parse_day("yesterday", now) do
    # Consider ambiguity:
    # now=1:00am -> should ask if today or yesterday
    now |> Timex.shift(days: -1) |> Map.take([:year, :month, :day])
  end

  defp parse_day_of_week(day_of_week, day_offset, now) do
    curr_day = Timex.weekday(now)
    target_day = Timex.day_to_num(day_of_week)

    case day_offset do
      "this" ->
        if target_day < curr_day, do: nil, else: target_day - curr_day

      "next" ->
        target_day + 7 - curr_day

      nil ->
        ## Consider ambiguity:
        ## now=mon, target=on mon -> should ask this mon or next mon
        if curr_day == target_day, do: nil, else: rem(target_day - curr_day + 7, 7)
    end
    |> case do
      nil -> nil
      offset -> now |> Timex.shift(days: offset) |> Map.take([:year, :month, :day])
    end
  end

  defp parse_period(period) when period in ~w[am a.m. morning], do: "am"
  defp parse_period(period) when period in ~w[pm p.m. afternoon evening night], do: "pm"
  defp parse_period(period) when period in ~w[midnight], do: "midnight"
  defp parse_period(period) when period in ~w[noon], do: "noon"
  defp parse_period(nil), do: nil

  defp resolve_period_and_hour(period, hour) do
    period = parse_period(period)

    case {period, hour} do
      {_, hour} when hour in 13..23 -> hour
      {nil, hour} -> hour
      {"midnight", hour} when hour in 0..3 -> hour
      {"midnight", hour} when hour in 11..12 -> rem(hour + 12, 24)
      {"noon", hour} when hour in 11..12 -> hour
      {"noon", 1} -> 13
      {"am", hour} when hour in 1..12 -> rem(hour, 12)
      {"pm", hour} when hour in 1..12 -> rem(hour, 12) + 12
      _ -> nil
    end
  end

  defp resolve_hms(h, nil, nil),
    do: %{hour: h, minute: 0, second: 0}

  defp resolve_hms(h, m, nil) when is_integer(m),
    do: %{hour: h, minute: m, second: 0}

  defp resolve_hms(h, m, s) when is_integer(m) and is_integer(s),
    do: %{hour: h, minute: m, second: s}
end
