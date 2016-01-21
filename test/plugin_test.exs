defmodule PluginTest do
  use ExSpec, async: true
  import ExUnit.CaptureLog
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


  describe "single plugin with multiple plugin statements" do
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


  describe "logging on halt" do
    defmodule PlugingWithHalt do
      use Plugin.Builder
      plugin :fn_1
      plugin :fn_2
      plugin :fn_3

      def fn_1(acc, _), do: acc |> Map.put(:fn_1, true)
      def fn_2(acc, _), do: acc |> Map.put(:fn_2, true) |> halt
      def fn_3(acc, _), do: acc |> Map.put(:fn_3, true)
    end

    defmodule PlugingWithHaltLogging do
      use Plugin.Builder, log_on_halt: :debug
      plugin PlugingWithHalt
    end

    it "logs output" do
      stdout = capture_log(fn ->Plugin.call(PlugingWithHaltLogging, %{}) end)
      assert String.contains?(stdout, "PluginTest.PlugingWithHaltLogging halted in PluginTest.PlugingWithHalt.call/2")
    end

    it "stops after fn_2" do
      acc = Plugin.call(PlugingWithHaltLogging, %{})
      assert %{fn_1: true} = acc
      assert %{fn_2: true} = acc
      assert %{halted: true} = acc
      refute acc |> Map.get(:fn_3)
    end
  end
end
