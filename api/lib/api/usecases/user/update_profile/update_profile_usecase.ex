defmodule Api.Usecases.User.UpdateProfile.UpdateProfileUsecase do
  @moduledoc """
  Updates a user's profile fields (name, bio, avatar_url).
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Repo
  alias Api.Usecases.User.UpdateProfile.UpdateProfileUsecaseDto

  def call(%UpdateProfileUsecaseDto{user: %User{} = user, attrs: attrs}) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end
end
