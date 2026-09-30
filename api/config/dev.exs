import Config

# Defaults below target the docker-compose stack (service hostnames like
# "postgres"/"minio"/"mailpit"); they're overridden by config/runtime.exs
# when the matching env vars are set (as docker-compose.yml does).
config :api, Api.Repo,
  url: "ecto://underlined:underlined@postgres/underlined_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :api, ApiWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_secret_key_base_change_me_dev_secret_key_base_change_me",
  watchers: []

config :api, Api.Accounts.Guardian,
  secret_key: "dev_guardian_secret_change_me_dev_guardian_secret_change_me"

config :api, Api.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "mailpit",
  port: 1025,
  ssl: false,
  tls: :never,
  auth: :never

config :ex_aws,
  access_key_id: "test",
  secret_access_key: "test",
  region: "us-east-1"

config :ex_aws, :s3,
  scheme: "http://",
  host: "s3mock",
  port: 9090

config :api, Api.Infra.S3ObjectStore,
  bucket: "avatars",
  public_endpoint: "http://localhost:9000"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false
