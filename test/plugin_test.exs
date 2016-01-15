defmodule PluginTest do
  use ExSpec, async: true
  doctest Plugin

  # we start with really stupid tests
  describe "single plug" do
    defmodule TestPlugin do
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
      assert %{halted: true} = Plugin.call(TestPlugin, %{test1: true})

    end

    it "returns acc otherwise" do
      a =  Plugin.call(TestPlugin, %{test2: true})
      refute Map.get(a, :halted)
      assert Map.get(a, :test2)
    end
  end
end
