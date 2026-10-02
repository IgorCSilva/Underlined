defmodule Api.Adapters.Like.LikeRepositoryAdapter do
  @moduledoc """
  Adapts a like repository (the adaptee) to the usecase layer. No domain
  entity crosses this boundary — callers only need the resulting
  liked?/like_count state.
  """

  def like_post(user, post_id, adaptee), do: adaptee.like_post(user, post_id)

  def unlike_post(user, post_id, adaptee), do: adaptee.unlike_post(user, post_id)
end
