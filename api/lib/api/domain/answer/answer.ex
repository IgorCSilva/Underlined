defmodule Api.Domain.Answer do
  @moduledoc """
  Pure business-rule answer entity. Holds no knowledge of Ecto, Postgres,
  or any other persistence detail.
  """

  defstruct [
    :id,
    :question_id,
    :body,
    :best,
    :user,
    :inserted_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          question_id: String.t(),
          body: String.t(),
          best: boolean(),
          user: Api.Domain.User.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
