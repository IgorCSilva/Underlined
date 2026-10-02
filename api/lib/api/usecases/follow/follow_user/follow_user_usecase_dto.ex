defmodule Api.Usecases.Follow.FollowUser.FollowUserUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Follow.FollowUser.FollowUserUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:follower, :followee_id]
  defstruct [:follower, :followee_id]

  @type t :: %__MODULE__{follower: %User{}, followee_id: Ecto.UUID.t()}
end
