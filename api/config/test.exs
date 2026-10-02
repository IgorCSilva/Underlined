import Config

# TEST_DATABASE_URL is deliberately separate from DATABASE_URL so running
# tests inside the docker-compose "api" container never touches the dev
# database (see runtime.exs, which only maps DATABASE_URL for :dev).
config :api, Api.Repo,
  url:
    System.get_env("TEST_DATABASE_URL") ||
      "ecto://underlined:underlined@postgres/underlined_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :api, ApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "nxj4Gil1/JFRXLfLYfrpgtgjxyG98nYLhcfeXYZxbxEvEiKpF2OAbEF+5+IM75w6",
  server: false

config :api, Api.Infrastructure.Guardian,
  secret_key: "test_guardian_secret_test_guardian_secret_test_guardian_secret"

# In test we don't send emails or hit real object storage — the Accounts
# context calls out to these Mox-based stubs instead (see test/support).
config :api, mailer: Api.MailerMock
config :api, object_store: Api.ObjectStoreMock

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
