defmodule ApiWeb.Router do
  use ApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_cookies
  end

  pipeline :authenticated do
    plug Api.Accounts.Pipeline
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

    get "/users/:id", ProfileController, :show

    get "/books", BookController, :index
    get "/books/:id", BookController, :show

    get "/posts/:id", PostController, :show

    scope "/" do
      pipe_through :authenticated

      get "/me", ProfileController, :me
      put "/me", ProfileController, :update
      put "/me/avatar", ProfileController, :update_avatar

      post "/books", BookController, :create

      post "/posts", PostController, :create
    end
  end
end
