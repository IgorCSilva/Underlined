defmodule Api.Usecases.Graph.GetGraph.GetGraphUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Graph.GetGraph.GetGraphUsecase`.
  """

  @enforce_keys [:user_id]
  defstruct [:user_id]

  @type t :: %__MODULE__{user_id: Ecto.UUID.t()}
end
