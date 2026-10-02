defmodule Api.Adapters.Posts do
  @moduledoc """
  Facade over the posts/likes/comments usecases.

  Callers build the DTO the target usecase expects and pass it in; this
  module only routes each DTO to its usecase.
  """

  alias Api.Usecases.Comment.CreateComment.CreateCommentUsecase
  alias Api.Usecases.Comment.ListComments.ListCommentsUsecase
  alias Api.Usecases.Like.LikePost.LikePostUsecase
  alias Api.Usecases.Like.UnlikePost.UnlikePostUsecase
  alias Api.Usecases.Post.CreatePost.CreatePostUsecase
  alias Api.Usecases.Post.GetPost.GetPostUsecase
  alias Api.Usecases.Post.ListPosts.ListPostsUsecase

  def create_post(dto) do
    CreatePostUsecase.call(dto, %CreatePostUsecase{repository: post_repository()})
  end

  def list_posts(dto) do
    ListPostsUsecase.call(dto, %ListPostsUsecase{repository: post_repository()})
  end

  def get_post(dto) do
    GetPostUsecase.call(dto, %GetPostUsecase{repository: post_repository()})
  end

  def like_post(dto) do
    LikePostUsecase.call(dto, %LikePostUsecase{repository: like_repository()})
  end

  def unlike_post(dto) do
    UnlikePostUsecase.call(dto, %UnlikePostUsecase{repository: like_repository()})
  end

  def create_comment(dto) do
    CreateCommentUsecase.call(dto, %CreateCommentUsecase{repository: comment_repository()})
  end

  def list_comments(dto) do
    ListCommentsUsecase.call(dto, %ListCommentsUsecase{repository: comment_repository()})
  end

  defp post_repository, do: Application.get_env(:api, :post_repository) |> Map.new()
  defp like_repository, do: Application.get_env(:api, :like_repository) |> Map.new()
  defp comment_repository, do: Application.get_env(:api, :comment_repository) |> Map.new()
end
