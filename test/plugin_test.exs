defmodule PluginTest do
  use ExSpec, async: true
  doctest Plugin

  describe "single plugin" do
    defmodule SinglePlugin do
      use Plugin.Builder
      plugin :test1, []

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


  describe "single plugin with multiple plug statements" do
    defmodule SinglePluginMultiStatements do
      use Plugin.Builder
      plugin :test1, []
      plugin :test2, []

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
      plugin :test1, []

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

    defmodule Plugin4EarlyHalt do
      use Plugin.Builder
      plugin :early_halt
      plugin Plugin1
      plugin Plugin2

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


  describe "plugins with configuration" do
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

    it "has information generated in `init`" do
      acc = Plugin.call(BuilderUsesPlugingWithConfig, %{})
      assert %{assigns: %{from: "0.0.0.0"}} = acc
    end

    it "has information passed on `plug` statement" do
      acc = Plugin.call(BuilderUsesPlugingWithConfig, %{})
      assert %{assigns: %{extra: "some_info"}} = acc
    end
  end
end
