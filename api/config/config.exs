# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :api,
  ecto_repos: [Api.Repo],
  env: config_env(),
  generators: [binary_id: true]

config :api, Api.Infrastructure.Guardian,
  issuer: "underlined_api",
  ttl: {15, :minutes}

config :api, :user_repository,
  adapter: Api.Adapters.User.UserRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.User.Postgres.UserRepository

config :api, :user_token_repository,
  adapter: Api.Adapters.UserToken.UserTokenRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.UserToken.Postgres.UserTokenRepository

config :api, :refresh_token_repository,
  adapter: Api.Adapters.RefreshToken.RefreshTokenRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.RefreshToken.Postgres.RefreshTokenRepository

config :api, :book_repository,
  adapter: Api.Adapters.Book.BookRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.Book.Postgres.BookRepository

config :api, :post_repository,
  adapter: Api.Adapters.Post.PostRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.Post.Postgres.PostRepository

config :api, :like_repository,
  adapter: Api.Adapters.Like.LikeRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.Like.Postgres.LikeRepository

config :api, :comment_repository,
  adapter: Api.Adapters.Comment.CommentRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.Comment.Postgres.CommentRepository

config :api, :follow_repository,
  adapter: Api.Adapters.Follow.FollowRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.Follow.Postgres.FollowRepository

config :api, :bookmark_repository,
  adapter: Api.Adapters.Bookmark.BookmarkRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.Bookmark.Postgres.BookmarkRepository

config :api, :keyword_repository,
  adapter: Api.Adapters.Keyword.KeywordRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.Keyword.Postgres.KeywordRepository

config :api, :connection_repository,
  adapter: Api.Adapters.Connection.ConnectionRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.Connection.Postgres.ConnectionRepository

config :api, :interest_profile_repository,
  adapter: Api.Adapters.InterestProfile.InterestProfileRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.InterestProfile.Postgres.InterestProfileRepository

config :api, :chain_repository,
  adapter: Api.Adapters.Chain.ChainRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.Chain.Postgres.ChainRepository

config :api, :graph_repository,
  adapter: Api.Adapters.Graph.GraphRepositoryAdapter,
  adaptee: Api.Infrastructure.Repository.Graph.Postgres.GraphRepository

config :api, cors_origin: "http://localhost:3000"
config :api, web_base_url: "http://localhost:3000"

# Community Health integration: fire-and-forget jobs run on their own queue so
# a slow/down CH service can never back up other background work. The
# adapter itself defaults to the no-op implementation (see
# Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop) unless config/runtime.exs enables
# the real HTTP client.
config :api, Oban,
  repo: Api.Repo,
  queues: [community_health: 5, interest_profiles: 2],
  plugins: [
    {Oban.Plugins.Pruner, max_age: :timer.hours(24 * 7)},
    # Rescues jobs orphaned by a container restart mid-execution (state
    # stuck at "executing" with no process left to ever finish them) —
    # otherwise they sit there forever instead of retrying.
    Oban.Plugins.Lifeline
  ]

config :api, community_health_default_community: "default"

config :api, ApiWeb.Gettext, default_locale: "en", locales: ~w(en pt_BR)

# Configures the endpoint
config :api, ApiWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: ApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Api.PubSub

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :api, Api.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
