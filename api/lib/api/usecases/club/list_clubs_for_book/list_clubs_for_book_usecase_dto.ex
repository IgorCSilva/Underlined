defmodule Api.Usecases.Club.ListClubsForBook.ListClubsForBookUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.ListClubsForBook.ListClubsForBookUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:book_id]
  defstruct [:book_id, :current_user]

  @type t :: %__MODULE__{book_id: Ecto.UUID.t(), current_user: %User{} | nil}
end
