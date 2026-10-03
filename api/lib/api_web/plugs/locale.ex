defmodule ApiWeb.Plugs.Locale do
  @moduledoc """
  Reads the request's `accept-language` header and activates the matching
  Gettext locale for the rest of the request, falling back to the
  configured default when the header is missing or names an unsupported
  locale.
  """

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    Gettext.put_locale(ApiWeb.Gettext, locale_for(conn))
    conn
  end

  defp locale_for(conn) do
    conn
    |> Plug.Conn.get_req_header("accept-language")
    |> List.first()
    |> normalize()
  end

  defp normalize(nil), do: default_locale()

  defp normalize(header) do
    header
    |> String.split(",")
    |> List.first()
    |> String.split(";")
    |> List.first()
    |> String.trim()
    |> String.replace("-", "_")
    |> find_supported()
  end

  defp find_supported(tag) do
    locales = supported_locales()

    cond do
      tag in locales -> tag
      String.downcase(tag) in Enum.map(locales, &String.downcase/1) ->
        Enum.find(locales, &(String.downcase(&1) == String.downcase(tag)))

      true ->
        language = tag |> String.split("_") |> List.first()
        Enum.find(locales, &(String.split(&1, "_") |> List.first() == language)) || default_locale()
    end
  end

  defp supported_locales do
    Application.get_env(:api, ApiWeb.Gettext, [])[:locales] || ["en"]
  end

  defp default_locale do
    Application.get_env(:api, ApiWeb.Gettext, [])[:default_locale] || "en"
  end
end
