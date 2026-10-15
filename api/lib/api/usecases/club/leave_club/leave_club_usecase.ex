defmodule Api.Usecases.Club.LeaveClub.LeaveClubUsecase do
  @moduledoc """
  Removes a user from a club. Idempotent.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.LeaveClub.LeaveClubUsecaseDto

  defstruct [:repository]

  # No Community Health call here: CH-Step 2's `ensure_member` is an
  # idempotent upsert with no corresponding "remove membership" endpoint
  # yet, so there's nothing safe to call on leave.
  def call(%LeaveClubUsecaseDto{user: user, club_id: club_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.leave_club(user, club_id, adaptee)
  end
end
