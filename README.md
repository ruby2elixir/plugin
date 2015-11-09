# Plugin

**TODO: Add description**

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
```
