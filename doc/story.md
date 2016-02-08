Plugin includes just the bare minimum code to help you structure your application in composable `Plug`-like blocks.


Plugin is Plug without web-logic and without `Conn`.

Instead you use a simple Elixir `Map` to pass your data for transformation through plugins.
You are free to give it more structure with a struct


## Rules:

Basically you split your requirements into reusable composable Plugins, group them with the `Plugin.Builder` and let your data flow through the stack of them.

Example:

We have a single search interface, that requests data from different backends and unifies them into a homogenius datastructure.

The requirements for each backend have some common logic, but also include some arbitrary business rules, like:
  - remove a parameter for some specific backends
  - change a parameter for some specific backends
  - rename a parameter for some specific backends
  - add a parameter for some specific backends
  - apply special transformation for results from some specific backends
  - etc.


We would like to reuse most of the logic in a clear and straightforward manner. Let's use `Plugin` for that.

We will model a transportation meta-search engine.

Input query:
  - country
  - city_from
  - city_to
  - price_min
  - price_max
  - selected_transportation_types
  - datetime_min
  - datetime_max

Backends:
  Trains:

  Busses:

  Airlines:


# tag the acc with a transportation type
defmodule TypeMatcher do
  use Plugin.Helpers
  def init(opts), do: opts
  def call(acc, opts) do
    assign(acc, :type, Keyword.get(opts, :type))
  end
end

# find the nearest city that supports chosen transportation type
# e.g.: nearest city with an airport for :airplane
defmodule CityAdjuster do
  use Plugin.Helpers
  def init(opts) do
    Keyword.get(opts, :field_name)
  end

  def call(acc, field_name) do
    city = Map.get(acc, field_name)
    type = assigned(acc, :type)
    acc |> Map.put(field_name, pick_nearest(type, city))
  end

  defp pick_nearest(type, country, city) do
    NearestCityService.get(type, city)
  end
end

defmodule NearestCityService do
  def get(:train, city) do
   case city do
      "brandenburg" -> "berlin-schönefeld"
      _ -> city
    end

  end

  def get(:airplane, city) do
    case city do
      "brandenburg" -> "berlin-schönefeld"
      _ -> city
    end
  end
end


defmodule Backend1 do
  use Plugin.Builder
  plugin TypeMatcher, type: :train
end

defmodule Backend2 do
  use Plugin.Builder
  plugin TypeMatcher, type: :airplane
end


Business Rules:
  - Backend1
    -

### Middleware Pattern - Why and When
  - http://www.blrice.net/blog/2015/09/18/a-middleware-stack-without-rack/
  - [Rack Middleware as a General Purpose Abstraction by Mitchell Hashimoto](https://www.youtube.com/watch?v=i6pyhq3ZvyI) + [Slides](https://speakerdeck.com/mitchellh/middleware-a-general-purpose-abstraction)
  - [Ruby Implementation](https://github.com/mitchellh/middleware)
