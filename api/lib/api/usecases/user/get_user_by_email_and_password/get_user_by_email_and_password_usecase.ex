defmodule Api.Usecases.User.GetUserByEmailAndPassword.GetUserByEmailAndPasswordUsecase do
  @moduledoc """
  Looks up a user by email and verifies the given password, returning `nil`
  when the email is unknown or the password doesn't match.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.User.GetUserByEmail.{GetUserByEmailUsecase, GetUserByEmailUsecaseDto}
  alias Api.Usecases.User.GetUserByEmailAndPassword.GetUserByEmailAndPasswordUsecaseDto

  def call(%GetUserByEmailAndPasswordUsecaseDto{email: email, password: password})
      when is_binary(email) and is_binary(password) do
    user = GetUserByEmailUsecase.call(%GetUserByEmailUsecaseDto{email: email})
    if User.valid_password?(user, password), do: user
  end
end
