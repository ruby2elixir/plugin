defmodule Plugin.Helpers do
  @doc false
  defmacro __using__(_opts) do
    quote do
      import Plugin.Helpers
    end
  end


  @doc """
  Assigns a value to a key in the acc

  ## Examples

      iex> acc.assigns[:hello]
      nil
      iex> acc = assign(acc, :hello, :world)
      iex> acc.assigns[:hello]
      :world

  """
  @spec assign(%{}, atom, term) :: %{}
  def assign(%{} = acc, key, value) when is_atom(key) do
     assigns = (Map.get(acc, :assigns) || %{})
     assigns = Map.put(assigns, key, value)
     Map.put(acc, :assigns, assigns)
  end

  @doc """
  Halts the Plug pipeline by preventing further plugs downstream from being
  invoked. See the docs for `Plug.Builder` for more information on halting a
  plug pipeline.
  """
  #@spec halt(t) :: t
  def halt(%{} = acc) do
    Map.put(acc, :halted, true)
  end
end
