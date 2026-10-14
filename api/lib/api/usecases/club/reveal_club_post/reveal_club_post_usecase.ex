defmodule Api.Usecases.Club.RevealClubPost.RevealClubPostUsecase do
  @moduledoc """
  Fetches a single club discussion post in full, bypassing spoiler
  blocking — backs the explicit "reveal anyway" action, which is the
  reader's own choice to spoil themselves, not a gap in the automatic
  protection applied by `Api.Usecases.Club.ListClubPosts.ListClubPostsUsecase`.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.RevealClubPost.RevealClubPostUsecaseDto

  defstruct [:repository]

  def call(%RevealClubPostUsecaseDto{post_id: post_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.get_post(post_id, adaptee)
  end
end
