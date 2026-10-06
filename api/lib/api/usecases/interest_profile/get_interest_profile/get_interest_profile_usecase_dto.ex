defmodule Api.Usecases.InterestProfile.GetInterestProfile.GetInterestProfileUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.InterestProfile.GetInterestProfile.GetInterestProfileUsecase`.
  """

  @enforce_keys [:user_id]
  defstruct [:user_id]

  @type t :: %__MODULE__{user_id: Ecto.UUID.t()}
end
