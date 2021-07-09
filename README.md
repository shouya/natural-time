# NaturalTime

A small and dirty Elixir library that attempts to parse date and time from natural english.

It is capable of parsing at least the following formats:

- `tomorrow 1pm`
- `1 p.m. tomorrow`
- `on next monday 2 in the morning`
- `10pm`
- `next fri at 5:10pm`
- `next fri 5:10pm`

I wrote this library mainly for my own use only. Therefore, some of the expected features may be missing, which includes:

- non-weekday dates (e.g. `2021-01-01 13:00`)
- seconds (e.g. `12:59:59`)
- dates without a time (e.g. `next monday`)
- time-of-day description without a specific time (e.g. `morning`, `midnight`)
- "next" with times (`next 2pm`)

That being said, these formats should be relatively simple to add and I will welcome your pull requests :)


## Installation

Find the latest version on hex and include it in your `mix.exs` as such.

```elixir
def deps do
  [
    {:natural_time, "~> 0.1.0"}
  ]
end
```

## Usage

The library exports a single module with a single function `NaturalTime.parse/2`.

```elixir
@doc """
Specify a string and a DateTime object indicating the reference time.

The timezone information in the reference time will be used for
inference. For example, if the reference time has timezone of
"UTC+1", then "2pm" will parse to 2pm in UTC+1 timezone.

Example usage:

    iex> now = Timex.parse!("2019-06-02T01:04:21+08:00", "{ISO:Extended}")
    iex> parse("10pm", now) == Timex.parse!("2019-06-02T22:00:00+08:00", "{ISO:Extended}")
    true
"""
@spec parse(String.t(), DateTime.t()) :: nil | DateTime.t()
def parse(str, rel \\ Timex.now())
```

It spits out `nil` if the string cannot be parsed. Otherwise a DateTime object will be returned. Check out the tests for how to use it.
