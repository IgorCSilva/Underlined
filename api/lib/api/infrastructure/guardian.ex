defmodule Api.Infrastructure.Guardian do
  use Guardian, otp_app: :api

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Infrastructure.Repository.User.Postgres.UserRepository

  def subject_for_token(%User{id: id}, _claims), do: {:ok, to_string(id)}
  def subject_for_token(_, _), do: {:error, :invalid_resource}

  def resource_from_claims(%{"sub" => id}) do
    case UserRepository.get_user(id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_claims), do: {:error, :invalid_claims}
end
