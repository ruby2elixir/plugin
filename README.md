# `Plugin` helps you to structure your business logic in composable blocks.

Basically a light version of [Plug](https://github.com/elixir-lang/plug). Most of the code is a straight copy from Plug,

Think:
  - `Plug` without web-specific logic and without a typed `Conn`.


## Story

After having structured my business logic  with `middleware` pattern recently to keep it simple, testable and composable I came to like that pattern very much.

If you take a look at [Phoenix](github.com/phoenixframework/phoenix/) you see how far this pattern can be pushed and how reusable your bits of logic become.


So, I'd like to have a small library to help me build small modules that can be stacked together and composed in each other. I looked on Github and found this package: https://github.com/liveforeverx/plugin.git. It's mostly a copy-paste from Plug with some changes.

It gave me the initial direction, but it had no unit tests and was quite unusable.

So, I rewrote some bits and here we are.



## Installation

  1. Add plugin to your list of dependencies in `mix.exs`:

        def deps do
          [{:plugin, "~> 0.1.0"}]
        end


## Usage

All the rules how you structure/implement Plugs apply here:
- Module Plugins
- Function Plugins
- Builder Plugins


Example for Builder plugins:

```elixir
defmodule Plugin1 do
  use Plugin.Builder
  plugin :first_fn

  def first_fn(acc, _) do
    Map.put(acc, :first_fn_passed, true)
  end
end

defmodule Plugin2 do
  use Plugin.Builder
  plugin :second_fn

  def second_fn(acc, _) do
    Map.put(acc, :second_fn_passed, true)
  end
end

defmodule Plugin3 do
  use Plugin.Builder
  plugin Plugin1
  plugin Plugin2
end

acc = Plugin.call(Plugin3, %{})
true = Map.get(acc, :first_fn_passed)
true = Map.get(acc, :second_fn_passed)
```

Module Plugin:


```elixir
defmodule PluginWithConfig do
  use Plugin.Helpers # small convenience helpers
  def init(opts) do
    Keyword.put(opts, :current_ip, "0.0.0.0")
  end

  def call(acc, opts) do
    acc
    |> assign(:from, Keyword.get(opts, :current_ip) )
    |> assign(:extra, Keyword.get(opts, :extra_info))
  end
end

defmodule BuilderUsesPlugingWithConfig do
  use Plugin.Builder

  plugin PluginWithConfig, extra_info: "some_info"
end

acc = Plugin.call(BuilderUsesPlugingWithConfig, %{})
%{assigns: %{from: "0.0.0.0"}} = acc
%{assigns: %{extra: "some_info"}} = acc
```


To learn more about Plug please watch following freshly (2016/01) released videos:
  - [Elixir Louisville: Plug, Friend of Web Developers](https://www.youtube.com/watch?v=-gev84S9_-c) -
  - [Elixir Louisville: Plug, Friend of Web Developers - Demo](https://www.youtube.com/watch?v=tfRD_e-yvOE)


## Most of the code is taken directly from `plug`.

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

## Some links why you might consider "Middleware Pattern" as a general solution pattern even outside of web request / response cycle:
  - https://twitter.com/mitchellh/status/237389160976101377
  - https://twitter.com/mitchellh/status/235211110087786496
  - http://programmers.stackexchange.com/questions/203314/what-is-the-middleware-pattern
  - http://blog.carbonfive.com/2014/12/14/composing-data-pipelines-mostly-stateless-web-applications-in-clojure/
  - https://speakerdeck.com/swlaschin/railway-oriented-programming-a-functional-approach-to-error-handling
