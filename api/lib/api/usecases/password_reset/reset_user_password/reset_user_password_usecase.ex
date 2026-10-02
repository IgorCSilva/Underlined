defmodule Api.Usecases.PasswordReset.ResetUserPassword.ResetUserPasswordUsecase do
  @moduledoc """
  Sets a new password and revokes every existing email token and refresh
  token the user had, so old sessions and confirmation links stop working.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.PasswordReset.ResetUserPassword.ResetUserPasswordUsecaseDto

  defstruct [:repository]

  def call(%ResetUserPasswordUsecaseDto{user: %User{} = user, attrs: attrs}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.reset_password(user, attrs, adaptee)
  end
end
