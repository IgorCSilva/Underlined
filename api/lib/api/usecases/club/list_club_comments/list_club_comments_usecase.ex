defmodule Api.Usecases.Club.ListClubComments.ListClubCommentsUsecase do
  @moduledoc """
  Top-level comments for a club post, oldest first, each with its (also
  oldest-first) replies.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.ListClubComments.ListClubCommentsUsecaseDto

  defstruct [:repository]

  def call(%ListClubCommentsUsecaseDto{club_post_id: club_post_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_comments(club_post_id, adaptee)
  end
end
