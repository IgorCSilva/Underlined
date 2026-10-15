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

      post "/connections/:connection_id/comments", ConnectionCommentController, :create
      put "/connections/:connection_id/comments/:id", ConnectionCommentController, :update

      post "/chains", ChainController, :create
      post "/chains/:chain_id/items", ChainController, :add_item
      put "/chains/:chain_id/items", ChainController, :reorder_items

      get "/reports/reasons", ReportController, :reasons
      post "/reports", ReportController, :create

      post "/users/:id/follow", FollowController, :create
      delete "/users/:id/follow", FollowController, :delete

      post "/books/:book_id/clubs", ClubController, :create
      post "/clubs/:id/membership", ClubController, :join
      delete "/clubs/:id/membership", ClubController, :leave
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
      get "/connections/:id", DebateController, :show
      get "/connections/:connection_id/comments", ConnectionCommentController, :index
      get "/chains", ChainController, :index
      get "/chains/:id", ChainController, :show
      get "/books/:id/page", BookController, :page
      get "/books/:book_id/clubs", ClubController, :index
      get "/clubs/:id", ClubController, :show
      get "/clubs/:id/members", ClubController, :members
      get "/keywords/:name", KeywordController, :show
    end
  end
end
