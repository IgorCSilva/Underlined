defmodule Api.Usecases.User.GetUserOrRaise.GetUserOrRaiseUsecase do
  @moduledoc """
  Looks up a user by id, raising `Ecto.NoResultsError` if none is found.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Repo
  alias Api.Usecases.User.GetUserOrRaise.GetUserOrRaiseUsecaseDto

  def call(%GetUserOrRaiseUsecaseDto{id: id}), do: Repo.get!(User, id)
end
