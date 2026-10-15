defmodule Api.Usecases.Debate.GetDebate.GetDebateUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Debate.GetDebate.GetDebateUsecase`.
  """

  @enforce_keys [:id]
  defstruct [:id]

  @type t :: %__MODULE__{id: Ecto.UUID.t()}
end
