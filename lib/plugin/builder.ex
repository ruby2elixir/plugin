defmodule Plugin.Builder do
  @moduledoc """
  Conveniences for building Plugins.

  This module can be `use`-d into a module in order to build
  a plugin pipeline:

      defmodule MyApp do
        use Plugin.Builder

        plugin Plugin.Logger
        plugin :hello, upper: true

        # A function from another module can be plugged too, provided it's
        # imported into the current module first.

        import AnotherModule, only: [interesting_plugin: 2]
        plugin :interesting_plugin

        def hello(acc, opts) do
          body = if opts[:upper], do: "WORLD", else: "world"
          Map.put(acc, :body, body)
        end
      end

  Multiple plugins can be defined with the `plug/2` macro, forming a pipeline.

  The plugins in the pipeline will be executed in the order they've been added
  through the `plugin/2` macro. In the example above, `Plugin.Logger` will be
  called first and then the `:hello` function plugin will be called on the
  resulting value.


  ## Options

  When used, the following options are accepted by `Plugin.Builder`:

    * `:log_on_halt` - accepts the level to log whenever the request is halted


  ## Plugin behaviour

  Internally, `Plugin.Builder` implements the `Plugin` behaviour, which means both
  the `init/1` and `call/2` functions are defined.

  By implementing the Plugin API, `Plugin.Builder` guarantees this module is a plugin
  and can be handed as part of another pipeline.

  ## Overriding the default plugin API functions

  Both the `init/1` and `call/2` functions defined by `Plugin.Builder` can be
  manually overridden. For example, the `init/1` function provided by

  `Plugin.Builder` returns the options that it receives as an argument, but its
  behaviour can be customized:

      defmodule PluginWithCustomOptions do
        use Plugin.Builder
        plugin Plugin.Logger
        def init(opts) do
          opts
        end
      end

  The `call/2` function that `Plugin.Builder` provides is used internally to
  execute all the plugins listed using the `plug` macro, so overriding the
  `call/2` function generally implies using `super` in order to still call the
  plugin chain:

      defmodule PluginWithCustomCall do
        use Plugin.Builder
        plugin Plugin.Logger

        def call(acc, _opts) do
          super(acc, opts) # calls Plugin.Logger
          assign(acc, :called_all_plugins, true)
        end
      end
  """

  @type plugin :: module | atom

  @doc false
  defmacro __using__(opts) do
    quote do
      @behaviour Plugin
      @plugin_builder_opts unquote(opts)

      def init(opts) do
        opts
      end

      def call(acc, opts) do
        plugin_builder_call(acc, opts)
      end

      defoverridable [init: 1, call: 2]

      import Plugin.Helpers
      import Plugin.Builder, only: [plugin: 1, plugin: 2]

      Module.register_attribute(__MODULE__, :plugins, accumulate: true)
      @before_compile Plugin.Builder
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    plugins      = Module.get_attribute(env.module, :plugins)
    builder_opts = Module.get_attribute(env.module, :plugin_builder_opts)

    if plugins == [] do
      raise "no plugins have been defined in #{inspect env.module}"
    end

    {acc, body} = Plugin.Builder.compile(env, plugins, builder_opts)

    quote do
      defp plugin_builder_call(unquote(acc), _), do: unquote(body)
    end
  end

  @doc """
  A macro that stores a new plugin. `opts` will be passed unchanged to the new
  plugin.

  This macro doesn't add any guards when adding the new plugin to the pipeline;
  for more information about adding plugins with guards see `compile/1`.

  ## Examples
      plugin Plugin.Logger             # Plugin module
      plugin :foo, some_options: true  # Plugin function
  """

  defmacro plugin(plugin, opts \\ []) do
    quote do
      @plugins {unquote(plugin), unquote(opts), true}
    end
  end

  @doc """
  Compiles a plugin pipeline.

  Each element of the plugin pipeline (according to the type signature of this
  function) has the form:

      {plugin_name, options, guards}

  Note that this function expects a reversed pipeline (with the last plugin that
  has to be called coming first in the pipeline).

  The function returns a tuple with the first element being a quoted reference
  to the value and the second element being the compiled quoted pipeline.

  ## Examples

      Plugin.Builder.compile(env, [
        {Plugin.Logger, [], true}, # no guards, as added by the Plugin.Builder.plugin/2 macro
        {Plugin.Head, [], quote(do: a when is_binary(a))}
      ], [])
  """
  @spec compile(Macro.Env.t, [{plugin, Plugin.opts, Macro.t}], Keyword.t) :: {Macro.t, Macro.t}
  def compile(env, pipeline, builder_opts) do
    acc = quote do: acc
    {acc, Enum.reduce(pipeline, acc, &quote_plugin(init_plugin(&1), &2, env, builder_opts))}
  end

  # Initializes the options of a Plugin at compile time.
  defp init_plugin({plugin, opts, guards}) do
    case Atom.to_char_list(plugin) do
      'Elixir.' ++ _ -> init_module_plugin(plugin, opts, guards)
      _              -> init_fun_plugin(plugin, opts, guards)
    end
  end

  defp init_module_plugin(plugin, opts, guards) do
    initialized_opts = plugin.init(opts)

    if function_exported?(plugin, :call, 2) do
      {:module, plugin, initialized_opts, guards}
    else
      raise ArgumentError, message: "#{inspect plugin} plugin must implement call/2"
    end
  end

  defp init_fun_plugin(plugin, opts, guards) do
    {:function, plugin, opts, guards}
  end

  # `acc` is a series of nested plugin calls in the form of
  # plugin3(plugin2(plugin1(acc))). `quote_plugin` wraps a new plugin around that series
  # of calls.
  defp quote_plugin({plugin_type, plugin, opts, guards}, acc, env, builder_opts) do
    call = quote_plugin_call(plugin_type, plugin, opts)

    error_message = case plugin_type do
      :module   -> "expected #{inspect plugin}.call/2 to return a Map"
      :function -> "expected #{plugin}/2 to return a Map"
    end

    quote do
      case unquote(compile_guards(call, guards)) do
        %{halted: true} = acc ->
          unquote(log_halt(plugin_type, plugin, env, builder_opts))
          acc
        %{} = acc ->
          unquote(acc)
        _ ->
          raise unquote(error_message)
      end
    end
  end

  defp quote_plugin_call(:function, plugin, opts) do
    quote do: unquote(plugin)(acc, unquote(Macro.escape(opts)))
  end

  defp quote_plugin_call(:module, plugin, opts) do
    quote do: unquote(plugin).call(acc, unquote(Macro.escape(opts)))
  end

  defp compile_guards(call, true) do
    call
  end

  defp compile_guards(call, guards) do
    quote do
      case true do
        true when unquote(guards) -> unquote(call)
        true -> acc
      end
    end
  end

  defp log_halt(plugin_type, plugin, env, builder_opts) do
    if level = builder_opts[:log_on_halt] do
      message = case plugin_type do
        :module   -> "#{inspect env.module} halted in #{inspect plugin}.call/2"
        :function -> "#{inspect env.module} halted in #{inspect plugin}/2"
      end

      quote do
        require Logger
        Logger.unquote(level)(unquote(message))
      end
    else
      nil
    end
  end
end
