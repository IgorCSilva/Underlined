defmodule ApiWeb.Router do
  use ApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_cookies
    plug ApiWeb.Plugs.Locale
  end

  pipeline :authenticated do
    plug Api.Infrastructure.Pipeline
  end

  pipeline :maybe_authenticated do
    plug Api.Infrastructure.MaybeAuthPipeline
  end

  scope "/api", ApiWeb do
    pipe_through :api

    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/refresh", AuthController, :refresh
    delete "/auth/logout", AuthController, :logout
    post "/auth/confirm/:token", AuthController, :confirm
    post "/auth/reset_password", AuthController, :request_password_reset
    put "/auth/reset_password/:token", AuthController, :reset_password

    get "/books", BookController, :index
    get "/books/:id", BookController, :show

    get "/posts/:post_id/comments", CommentController, :index

    scope "/" do
      pipe_through :authenticated

      get "/me", ProfileController, :me
      put "/me", ProfileController, :update
      put "/me/avatar", ProfileController, :update_avatar

      post "/books", BookController, :create

      get "/posts/following", PostController, :following
      post "/posts", PostController, :create
      put "/posts/:id", PostController, :update

      post "/posts/:post_id/likes", LikeController, :create
      delete "/posts/:post_id/likes", LikeController, :delete

      get "/me/bookmarks", BookmarkController, :index
      post "/posts/:post_id/bookmarks", BookmarkController, :create
      delete "/posts/:post_id/bookmarks", BookmarkController, :delete

      post "/posts/:post_id/comments", CommentController, :create
      put "/posts/:post_id/comments/:id", CommentController, :update

      post "/posts/:post_id/connections", ConnectionController, :create

      post "/chains", ChainController, :create
      post "/chains/:chain_id/items", ChainController, :add_item
      put "/chains/:chain_id/items", ChainController, :reorder_items

      get "/reports/reasons", ReportController, :reasons
      post "/reports", ReportController, :create

      post "/users/:id/follow", FollowController, :create
      delete "/users/:id/follow", FollowController, :delete
    end

    scope "/" do
      pipe_through :maybe_authenticated

      get "/users/:id", ProfileController, :show
      get "/users/:id/interests", ProfileController, :interests
      get "/users/:id/graph", ProfileController, :graph
      get "/users/:id/community_health", ProfileController, :community_health
      get "/posts", PostController, :index
      get "/posts/:id", PostController, :show
      get "/posts/:id/related", PostController, :related
      get "/posts/:id/connections", ConnectionController, :index
      get "/chains", ChainController, :index
      get "/chains/:id", ChainController, :show
      get "/books/:id/page", BookController, :page
      get "/keywords/:name", KeywordController, :show
    end
  end
end
