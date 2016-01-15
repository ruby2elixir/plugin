defmodule Plugin do
  @moduledoc """
  Module for implementing plugin-ing, heavily inspired by `plug`, but possible to use for different
  conditions.

  There are two kind of plugs: function plugs and module plugs.

  #### Function plugins

  A function plugin is any function that receives a connection and a set of
  options and returns a connection. Its type signature must be:
      (%{}, Plugin.opts) :: %{}

  #### Module plugins

  A module plugin is an extension of the function plugin. It is a module that must
  export:

  * a `call/2` function with the signature defined above
  * an `init/1` function which takes a set of options and initializes it.

  The result returned by `init/1` is passed as second argument to `call/2`. Note
  that `init/1` may be called during compilation and as such it must not return
  pids, ports or values that are not specific to the runtime.
  The API expected by a module plugin is defined as a behaviour by the
  `Plugin` module (this module).

  ## The Plugin pipeline

  The `Plugin.Builder` module provides conveniences for building plugin
  pipelines.
  """

  @type opts :: tuple | atom | integer | float | [opts]

  use Behaviour
  use Application

  defcallback init(opts) :: opts
  defcallback call(%{}, opts) :: %{}

  @doc """
  Apply plugin to an acc with given optins.
  """
  def call(plugin, acc, opts \\ []) do
    case plugin.call(acc, opts) do
      %{} = res ->
        res
      _ ->
        raise "expected #{inspect plugin}.call/2 to return a Map."
    end

  end

  @doc false
  def start(_type, _args) do
    {:ok, self}
  end
end
