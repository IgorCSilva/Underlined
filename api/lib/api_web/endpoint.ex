defmodule ApiWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :api

  # Serve at "/" the static files from "priv/static" directory (avatars fallback, robots.txt, etc).
  plug Plug.Static,
    at: "/",
    from: :api,
    gzip: false,
    only: ApiWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :api
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # The Nuxt frontend runs on a different origin in dev, so requests need
  # CORS with credentials allowed (the refresh token travels as an
  # HttpOnly cookie). Re-reading config in `call/2` (rather than passing it
  # to `plug CORSPlug, origin: ...` directly) matters because Plug bakes
  # `init/1` options in at compile time, before config/runtime.exs — which is
  # what actually applies docker-compose's CORS_ORIGIN — has run.
  plug :cors

  plug ApiWeb.Router

  defp cors(conn, _opts) do
    origin = Application.get_env(:api, :cors_origin, "http://localhost:3000")
    CORSPlug.call(conn, CORSPlug.init(origin: [origin], credentials: true))
  end
end
