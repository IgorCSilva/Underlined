defmodule Api.Usecases.Keyword.GetKeywordPage.GetKeywordPageUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Keyword.GetKeywordPage.GetKeywordPageUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:name]
  defstruct [:name, :before, :current_user]

  @type t :: %__MODULE__{
          name: String.t(),
          before: String.t() | nil,
          current_user: %User{} | nil
        }
end
