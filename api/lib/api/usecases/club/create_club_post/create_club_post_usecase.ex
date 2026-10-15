defmodule Api.Usecases.Club.CreateClubPost.CreateClubPostUsecase do
  @moduledoc """
  Posts a message to a club's discussion, optionally tagged to one of its
  chapters. Only an existing member of the club may post — enforced by
  the repository.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.CreateClubPost.CreateClubPostUsecaseDto

  defstruct [:repository]

  def call(%CreateClubPostUsecaseDto{user: user, club_id: club_id, attrs: attrs}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.create_post(user, club_id, attrs, adaptee)
  end
end
