defmodule Api.Usecases.Club.ListClubPosts.ListClubPostsUsecase do
  @moduledoc """
  Lists a club's discussion posts, grouped general-first then by chapter
  schedule order (the grouping itself is left to the caller to render as
  headings). Open to everyone, same as the club itself — but a post
  tagged beyond `current_user`'s own reading progress comes back
  spoiler-blocked (see `Api.Domain.ClubPost.spoiler_blocked`).

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.ListClubPosts.ListClubPostsUsecaseDto

  defstruct [:repository]

  def call(%ListClubPostsUsecaseDto{club_id: club_id, current_user: current_user}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_posts(club_id, current_user, adaptee)
  end
end
