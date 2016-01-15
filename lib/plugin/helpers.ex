defmodule Plugin.Helpers do

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
