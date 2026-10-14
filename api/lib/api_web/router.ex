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

      post "/clubs/:club_id/chapters", ClubChapterController, :create
      put "/clubs/:club_id/chapters/:id/current", ClubChapterController, :set_current

      post "/clubs/:club_id/posts", ClubPostController, :create

      post "/club_posts/:club_post_id/comments", ClubCommentController, :create
      put "/club_posts/:club_post_id/comments/:id", ClubCommentController, :update

      get "/clubs/:club_id/reading_progress", ClubReadingProgressController, :show
      put "/clubs/:club_id/reading_progress", ClubReadingProgressController, :update

      post "/books/:book_id/questions", QuestionController, :create
      post "/questions/:question_id/answers", AnswerController, :create
      put "/answers/:id/best", AnswerController, :mark_best
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
      get "/clubs", ClubController, :all
      get "/clubs/:id", ClubController, :show
      get "/clubs/:id/members", ClubController, :members
      get "/clubs/:club_id/chapters", ClubChapterController, :index
      get "/clubs/:club_id/posts", ClubPostController, :index
      get "/club_posts/:id/reveal", ClubPostController, :reveal
      get "/club_posts/:club_post_id/comments", ClubCommentController, :index
      get "/keywords/:name", KeywordController, :show
      get "/questions/:id", QuestionController, :show
      get "/questions/:question_id/answers", AnswerController, :index
    end
  end
end
