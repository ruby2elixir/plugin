defmodule PluginTest do
  use ExSpec, async: true
  doctest Plugin

  # we start with really stupid tests
  describe "single plugin" do
    defmodule SinglePlugin do
      use Plugin.Builder
      plug :test1, []

      def test1(acc, _) do
        if acc[:test1] do
          halt(acc)
        else
          acc
        end
      end
    end

    it "returns halted acc for test1" do
      assert %{halted: true} = Plugin.call(SinglePlugin, %{test1: true})
    end

    it "returns non-halted acc otherwise" do
      a =  Plugin.call(SinglePlugin, %{test2: true})
      refute Map.get(a, :halted)
      assert Map.get(a, :test2)
    end
  end


  describe "single plugin multiple plug statements" do
    defmodule SinglePluginMultiStatements do
      use Plugin.Builder
      plug :test1, []
      plug :test2, []

      def test1(acc, _) do
        if acc[:test1] do
          halt(acc)
        else
          acc
        end
      end

      def test2(acc, _) do
        acc = Map.put(acc, :test3, "added" )
        halt(acc)
      end
    end

    it "returns halted acc for test2" do
      acc = Plugin.call(SinglePluginMultiStatements, %{test2: true})
      assert %{halted: true}   = acc
      assert %{test3: "added"} = acc
    end
  end


  describe "requires a map as returned value" do
    defmodule NoMapReturn do
      use Plugin.Builder
      plug :test1, []

      def test1(_acc, _) do
        "invalid string"
      end
    end

    it "raises" do
      assert_raise RuntimeError, "expected test1/2 to return a Map", fn ->
        Plugin.call(NoMapReturn, %{test2: true})
      end
    end
  end


  describe "composed plugins" do
    defmodule Plugin1 do
      use Plugin.Builder
      plug :first_fn

      def first_fn(acc, _) do
        Map.put(acc, :first_fn_passed, true)
      end
    end

    defmodule Plugin2 do
      use Plugin.Builder
      plug :second_fn

      def second_fn(acc, _) do
        Map.put(acc, :second_fn_passed, true)
      end
    end

    defmodule Plugin3 do
      use Plugin.Builder
      plug Plugin1
      plug Plugin2
    end

    defmodule Plugin4EarlyHalt do
      use Plugin.Builder
      plug :early_halt
      plug Plugin1
      plug Plugin2

      def early_halt(acc, _) do
        halt(acc)
      end
    end

    it "executes plugins in proper order" do
      acc = Plugin.call(Plugin3, %{})
      assert Map.get(acc, :first_fn_passed)
      assert Map.get(acc, :second_fn_passed)
    end

    it "returns halted response earlier" do
      acc = Plugin.call(Plugin4EarlyHalt, %{})
      refute Map.get(acc, :first_fn_passed)
      refute Map.get(acc, :second_fn_passed)
    end
  end
end
