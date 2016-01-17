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

    it "retains the old values" do
      acc = %{} |> assign(:second, 2) |> assign(:first, 1)
      assert acc == %{assigns: %{first: 1, second: 2}}
    end
  end


  describe "assigned" do
    it "returns a value from assigns in acc"  do
      acc = %{} |> assign(:second, 2) |> assign(:first, 1)
      assert (acc |> assigned(:second)) == 2
    end

    it "returns nil, if assigns were not set" do
      assert (%{} |> assigned(:second)) == nil
    end
  end

end
