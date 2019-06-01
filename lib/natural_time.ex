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
  @relative_pat "(?<relative>(this|next))"
  @day_of_week_pat "(?<day_of_week>(monday|tuesday|wednesday|thursday|friday|saturday|sunday))"
  @time_of_day_pat "(?<time_of_day>(morning|noon|afternoon|evening|night|midnight))"
  @period_pat "(?<period>(am|pm|(((at|in) the )?#{@time_of_day_pat})))"
  @time_pat "(?<hr>\\d{1,2})(:(?<min>\\d{1,2}))?\\s*#{@period_pat}"
  @day_pat "(#{@day_name_pat}|(#{@relative_pat}|on)\\s+#{@day_of_week_pat})"
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
  def parse(input, relative_to \\ Timex.local()) do
    @all_patterns
    |> Stream.map(&Regex.run(&1, input, capture: :named_captures))
    |> Enum.reduce(:not_found, fn
      :not_found, nil -> :not_found
      :not_found, cap -> {:found, cap}
      {:found, cap}, _ -> {:found, cap}
    end)
    |> case do
      {:found, cap} -> resolve_capture(cap, relative_to)
      :not_found -> {:error, :not_found}
    end
  end

  defp resolve_capture(cap, relative_to) do
    [:date, :hour, :minute]
    |> Enum.map(&{&1, resolve_capture(cap, &1, relative_to)})
    |> IO.inspect()
  end

  defp resolve_capture(cap, :date, relative_to) do
    nil
  end

  defp resolve_capture(cap, :hour, relative_to) do
    nil
  end

  defp resolve_capture(cap, :minute, relative_to) do
    nil
  end
end
