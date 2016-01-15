defmodule PluginTest do
  use ExUnit.Case
  doctest Plugin

  defmodule PluginWithCustomOptions do
    use Plugin.Builder
    plug :reverse

    def init(opts) do
      opts
    end

    def call(acc, opts) do
      super(acc, opts)
      reverse(acc, opts)
    end

    def reverse(acc, opts) do
      IO.inspect acc
      {:cont, (acc |> String.reverse)}
    end
  end


  # test

  defmodule MyApp do
    use Plugin.Builder
    plug :hello, upper: true
    plug :reversing_function
    #plug PluginWithCustomOptions

    def hello(value, opts) do
      if opts[:upper],
        do:   {:cont,"WORLD" },
        else: {:cont,"world" }
    end

    def reversing_function(value, _opts) do
      IO.inspect value
      {:cont, (value |> String.reverse)}
    end
  end

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "plugin works" do
    # a = Plugin.call(MyApp, "some")
    # IO.puts "********* "
    # IO.inspect(a)
  end


  ###### another test

  defmodule TestPlugin do
    use Plugin.Builder
    plug :test1, []
    def test1(acc, _) do
      if acc[:test1] do
        {:stop, :test1}
      else
        {:cont, :test2}
      end
    end
  end


  test "test plugin" do
    #a = Plugin.call(TestNextPlugin, %{test2: true}) # |> IO.inspect
    #Plugin.call(TestNextPlugin, %{test1: true})
    TestPlugin.call(%{test1: true}, []) |> IO.inspect

  end

end
