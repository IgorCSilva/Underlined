defmodule ApiWeb.PostController do
  use ApiWeb, :controller

  alias Api.Adapters.Posts
  alias Api.Usecases.Post.CreatePost.CreatePostUsecaseDto
  alias Api.Usecases.Post.GetPost.GetPostUsecaseDto
  alias Api.Usecases.Post.ListFollowingPosts.ListFollowingPostsUsecaseDto
  alias Api.Usecases.Post.ListPosts.ListPostsUsecaseDto
  alias Api.Usecases.Post.RelatedPosts.RelatedPostsUsecaseDto

  action_fallback ApiWeb.FallbackController

  def index(conn, params) do
    posts =
      Posts.list_posts(%ListPostsUsecaseDto{
        before: params["before"],
        current_user: current_user(conn)
      })

    render(conn, :index, posts: posts)
  end

  def following(conn, params) do
    posts =
      Posts.list_following_posts(%ListFollowingPostsUsecaseDto{
        user: current_user(conn),
        before: params["before"]
      })

    render(conn, :index, posts: posts)
  end

  def show(conn, %{"id" => id}) do
    case Posts.get_post(%GetPostUsecaseDto{id: id, current_user: current_user(conn)}) do
      nil -> {:error, :not_found}
      post -> render(conn, :show, post: post)
    end
  end

  def related(conn, %{"id" => id}) do
    with {:ok, posts} <-
           Posts.related_posts(%RelatedPostsUsecaseDto{id: id, current_user: current_user(conn)}) do
      render(conn, :index, posts: posts)
    end
  end

  def create(conn, %{"post" => post_params}) do
    with {:ok, post} <-
           Posts.create_post(%CreatePostUsecaseDto{user: current_user(conn), attrs: post_params}) do
      conn
      |> put_status(:created)
      |> render(:show, post: post)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
