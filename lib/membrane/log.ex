defmodule Membrane.Log do
  @moduledoc """
  Mixin for logging using simple functions such as info/1, debug/1 in other
  modules.
  """

  use Bunch
  alias Membrane.Log.Router

  defmacro __using__(args) do
    passed_tags = args |> Keyword.get(:tags, []) |> Bunch.listify()
    previous_tags = Module.get_attribute(__CALLER__.module, :logger_default_tags) || []
    default_tags = (passed_tags ++ previous_tags) |> Enum.dedup()
    Module.put_attribute(__CALLER__.module, :logger_default_tags, default_tags)

    if args |> Keyword.get(:import, true) do
      quote location: :keep do
        import Membrane.Log
      end
    end
  end

  defmacro debug(message, tags \\ []) do
    do_log(:debug, message, tags)
  end

  defmacro info(message, tags \\ []) do
    do_log(:info, message, tags)
  end

  defmacro warn(message, tags \\ []) do
    do_log(:warn, message, tags)
  end

  defmacro warn_error(message, reason, tags \\ []) do
    message =
      quote do
        use Bunch

        [
          "Encountered an error.\n",
          "Reason: #{inspect(unquote(reason))}\n",
          unquote(message),
          "\n",
          """
          Stacktrace:
          #{Bunch.stacktrace()}
          """
        ]
      end

    quote location: :keep do
      unquote(do_log(:warn, message, tags))
      unquote({:error, reason})
    end
  end

  defmacro or_warn_error(v, message, tags \\ []) do
    quote location: :keep do
      with {:ok, value} <- unquote(v) do
        {:ok, value}
      else
        {:error, reason} ->
          Membrane.Log.warn_error(unquote(message), reason, unquote(tags))
      end
    end
  end

  defmacro log(level, message, tags \\ []) do
    do_log(level, message, tags)
  end

  defp do_log(level, message, tags) do
    config = Application.get_env(:membrane_core, Membrane.Logger, [])
    router_level = config |> Keyword.get(:level, :debug)
    router_level_val = router_level |> Router.level_to_val()

    send_code =
      quote do
        alias Membrane.Log.Router
        use Bunch

        Router.send_log(
          unquote(level),
          unquote(message),
          Membrane.Time.pretty_now(),
          (unquote(tags) |> Bunch.listify()) ++ @logger_default_tags
        )
      end

    cond do
      not is_atom(level) ->
        quote location: :keep do
          if level_val >= unquote(router_level_val) do
            unquote(send_code)
          end

          :ok
        end

      level |> Router.level_to_val() >= 1 ->
        quote location: :keep do
          unquote(send_code)
          :ok
        end

      true ->
        quote location: :keep, bind_quoted: [message: message, tags: tags] do
        end
    end
  end
end
