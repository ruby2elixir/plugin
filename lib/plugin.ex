defmodule Plugin do
  @moduledoc """
  Module for implementing plugin-ing, heavily inspired by `plug`, but possible to use for different
  conditions.

  There are two kind of plugs: function plugs and module plugs.

  #### Function plugs

  A function plug is any function that receives a connection and a set of
  options and returns a connection. Its type signature must be:
      (Plug.Conn.t, Plug.opts) :: Plug.Conn.t

  #### Module plugs

  A module plug is an extension of the function plug. It is a module that must
  export:

  * a `call/2` function with the signature defined above
  * an `init/1` function which takes a set of options and initializes it.

  The result returned by `init/1` is passed as second argument to `call/2`. Note
  that `init/1` may be called during compilation and as such it must not return
  pids, ports or values that are not specific to the runtime.
  The API expected by a module plug is defined as a behaviour by the
  `Plugin` module (this module).

  ## The Plugin pipeline

  The `Plugin.Builder` module provides conveniences for building plug
  pipelines.
  """

  @type opts :: tuple | atom | integer | float | [opts]

  use Behaviour
  use Application

  defcallback init(opts) :: opts
  defcallback call(any, opts) :: {:cont | :stop, any}

  @doc """
  Apply plugin to a value with given optins.
  """
  def call(plugin, value, opts \\ []) do
    case plugin.call(value, opts) do
      {control, acc} when control in [:stop, :cont] ->
        acc
      _ ->
        raise "expected #{inspect plugin}.call/2 to return :cont or :stop as first element of tuple)"
    end
  end

  @doc false
  def start(_type, _args) do
    {:ok, self}
  end
end
