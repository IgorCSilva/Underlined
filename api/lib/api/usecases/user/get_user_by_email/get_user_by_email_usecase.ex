defmodule Api.Usecases.User.GetUserByEmail.GetUserByEmailUsecase do
  @moduledoc """
  Looks up a user by email (case-insensitive).
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Repo
  alias Api.Usecases.User.GetUserByEmail.GetUserByEmailUsecaseDto

  def call(%GetUserByEmailUsecaseDto{email: email}) when is_binary(email) do
    Repo.get_by(User, email: String.downcase(email))
  end
end
