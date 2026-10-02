defmodule Api.Usecases.User.UpdateAvatar.UpdateAvatarUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.User.UpdateAvatar.UpdateAvatarUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :binary, :content_type]
  defstruct [:user, :binary, :content_type]

  @type t :: %__MODULE__{user: %User{}, binary: binary(), content_type: String.t()}
end
