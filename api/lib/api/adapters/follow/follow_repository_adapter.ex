defmodule Api.Adapters.Follow.FollowRepositoryAdapter do
  @moduledoc """
  Adapts a follow repository (the adaptee) to the usecase layer. No domain
  entity crosses this boundary — callers only need the resulting
  following? state.
  """

  def follow_user(follower, followee_id, adaptee), do: adaptee.follow_user(follower, followee_id)

  def unfollow_user(follower, followee_id, adaptee),
    do: adaptee.unfollow_user(follower, followee_id)
end
