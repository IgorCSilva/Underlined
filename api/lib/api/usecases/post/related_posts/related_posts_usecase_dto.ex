defmodule Api.Usecases.Post.RelatedPosts.RelatedPostsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Post.RelatedPosts.RelatedPostsUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:id]
  defstruct [:id, :current_user]

  @type t :: %__MODULE__{id: Ecto.UUID.t(), current_user: %User{} | nil}
end
