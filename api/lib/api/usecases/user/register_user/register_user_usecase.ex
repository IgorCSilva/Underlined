defmodule Api.Usecases.User.RegisterUser.RegisterUserUsecase do
  @moduledoc """
  Creates a new user from registration attributes.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Repo
  alias Api.Usecases.User.RegisterUser.RegisterUserUsecaseDto

  def call(%RegisterUserUsecaseDto{attrs: attrs}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end
end
