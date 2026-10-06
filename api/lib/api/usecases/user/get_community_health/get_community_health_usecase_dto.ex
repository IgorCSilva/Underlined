defmodule Api.Usecases.User.GetCommunityHealth.GetCommunityHealthUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.User.GetCommunityHealth.GetCommunityHealthUsecase`.
  """

  @enforce_keys [:user_id]
  defstruct [:user_id]

  @type t :: %__MODULE__{user_id: Ecto.UUID.t()}
end
