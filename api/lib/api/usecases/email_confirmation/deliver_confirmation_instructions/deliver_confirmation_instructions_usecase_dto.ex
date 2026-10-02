defmodule Api.Usecases.EmailConfirmation.DeliverConfirmationInstructions.DeliverConfirmationInstructionsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.EmailConfirmation.DeliverConfirmationInstructions.DeliverConfirmationInstructionsUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :confirmation_url_fun]
  defstruct [:user, :confirmation_url_fun]

  @type t :: %__MODULE__{user: %User{}, confirmation_url_fun: (String.t() -> String.t())}
end
