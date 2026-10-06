defmodule Api.Infrastructure.InterestProfile.RecomputeInterestProfileWorker do
  @moduledoc """
  Recomputes one user's interest profile off the request path, enqueued by
  `CreatePostUsecase` right after a post commits — publishing is the only
  thing that changes a user's keyword usage, so that's the only place this
  needs to be triggered from.
  """

  use Oban.Worker, queue: :interest_profiles, max_attempts: 5

  alias Api.Infrastructure.Repository.InterestProfile.Postgres.InterestProfileRepository

  def enqueue(user_id) do
    %{"user_id" => user_id} |> new() |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    InterestProfileRepository.recompute(user_id)
    :ok
  end
end
