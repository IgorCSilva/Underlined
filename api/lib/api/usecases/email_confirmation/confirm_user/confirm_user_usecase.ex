defmodule Api.Usecases.EmailConfirmation.ConfirmUser.ConfirmUserUsecase do
  @moduledoc """
  Verifies a confirmation token and marks the user as confirmed.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.EmailConfirmation.ConfirmUser.ConfirmUserUsecaseDto

  defstruct [:repository]

  def call(%ConfirmUserUsecaseDto{token: token}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    case adapter.verify_email_token(token, "confirm", adaptee) do
      nil ->
        {:error, :invalid_token}

      user ->
        case adapter.confirm_user(user, adaptee) do
          {:ok, user} -> {:ok, user}
          {:error, _changeset} -> {:error, :invalid_token}
        end
    end
  end
end
