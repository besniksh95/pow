defmodule Authex.Extension.Phoenix.Messages do
  @moduledoc """
  Module that handles messages for extensions.

  ## Usage

      defmodule MyAppWeb.Authex.Messages do
        use Authex.Phoenix.Messages
        use Authex.Extension.Phoenix.Messages,
          extensions: [AuthexExtensionOne, AuthexExtensionTwo]

        def authex_extension_one_a_message(_conn), do: "A message."
      end
  """
  alias Authex.{Config, Extension}

  defmacro __using__(config) do
    quote do
      unquote(config)
      |> unquote(__MODULE__).__messages_extensions__()
      |> Enum.map(&unquote(__MODULE__).__define_message_methods__/1)
    end
  end

  @spec __messages_extensions__(Config.t()) :: [atom()]
  def __messages_extensions__(config) do
    config
    |> Extension.Config.extensions()
    |> Enum.map(&Module.concat([&1, "Phoenix", "Messages"]))
    |> Enum.filter(&Code.ensure_compiled?/1)
    |> Enum.reject(&is_nil/1)
  end

  defmacro __define_message_methods__(extension) do
    quote do
      extension = unquote(extension)

      for {fallback_method, 1} <- extension.__info__(:functions) do
        method_name = unquote(__MODULE__).method_name(extension, fallback_method)
        unquote(__MODULE__).__define_message_method__(extension, method_name, fallback_method)
      end
    end
  end

  defmacro __define_message_method__(extension, method_name, fallback_method) do
    quote bind_quoted: [extension: extension, method_name: method_name, fallback_method: fallback_method] do
      @spec unquote(method_name)(Conn.t()) :: binary()
      def unquote(method_name)(conn) do
        unquote(extension).unquote(fallback_method)(conn)
      end

      defoverridable [{method_name, 1}]
    end
  end

  @spec method_name(atom(), atom()) :: atom()
  def method_name(extension, type) do
    namespace =
      extension
      |> Module.split()
      |> List.first()
      |> Macro.underscore()

    String.to_atom("#{namespace}_#{type}")
  end
end