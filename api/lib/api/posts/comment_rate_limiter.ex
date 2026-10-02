defmodule Api.Posts.CommentRateLimiter do
  @moduledoc """
  In-memory (ETS) rate limiter for comment creation. No Redis needed while
  the app runs on a single Gigalixir replica (same reasoning as Step 4's
  deferred feed cache) — revisit if/when there's more than one replica.
  """

  use Hammer, backend: :ets
end
