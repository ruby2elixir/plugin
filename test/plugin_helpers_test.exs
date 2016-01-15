defmodule PluginHelpersTest do
  use ExSpec, async: true

  import Plugin.Helpers


  describe "halt" do
    it "puts `halt` field into acc" do
      assert halt(%{})  == %{halted: true}
    end
  end


  describe "assign" do
    it "puts a value for specified key into `assigns` Map on acc" do
      acc = %{}
      assert assign(acc, :my_key, "my_value")  == %{assigns: %{my_key: "my_value"}}
    end
  end

end
