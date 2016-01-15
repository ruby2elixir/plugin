# Plugin

Basically a light version of [Plug](https://github.com/elixir-lang/plug).

Think:
  - `Plug` without web-specific logic and without a typed `Conn` type.


## Story

After having structured my business logic  with `middleware` pattern recently to keep it simple, testable and composable I came to like that pattern very much.

If you take a look at [Phoenix](github.com/phoenixframework/phoenix/) you see how far this pattern can be pushed and how reusable your bits of logic become.


So, I'd like to have a small library to help me build small modules that can be stacked together and composed in each other. I looked on Github and found this package: https://github.com/liveforeverx/plugin.git. It's mostly a copy-paste from Plug with some changes.

It gave me the initial direction, but it had no unit tests and was quite unusable.

So, I rewrote some bits and here we are:

- Plugin - to structure your business logic in composable blocks!



## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add plugin to your list of dependencies in `mix.exs`:

        def deps do
          [{:plugin, "~> 0.0.1"}]
        end

  2. Ensure plugin is started before your application:

        def application do
          [applications: [:plugin]]
        end

## Inspired by `plug`

License for part of codes:

Copyright (c) 2013 Plataformatec.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

Modified by

## Usage

```elixir
defmodule Test do
  use Plugin.Builder

  plug :test1, []
  plug :test2, []

  def test1(acc, _) do
    if acc[:test1] do
      {:stop, :test1}
    else
      {:cont, acc}
    end
  end

  def test2(acc, _) do
    {:stop, :test2}
  end
end

defmodule TestNext do
  use Plugin.Builder

  plug Test

end

Plugin.call(TestNext, %{test1: true})
TestNext.call(%{test1: true})
```
