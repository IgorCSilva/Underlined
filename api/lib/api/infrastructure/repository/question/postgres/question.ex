defmodule Api.Infrastructure.Repository.Question.Postgres.Question do
  @moduledoc """
  Postgres-backed question entity (Ecto schema). This is database
  structure, not a business-rule entity — it belongs to infrastructure,
  not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Book.Postgres.Book
  alias Api.Infrastructure.Repository.Passage.Postgres.Passage
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "questions" do
    field :body, :string
    field :answer_count, :integer, default: 0

    belongs_to :user, User
    belongs_to :book, Book
    belongs_to :passage, Passage

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(question, attrs) do
    question
    |> cast(attrs, [:user_id, :book_id, :passage_id, :body])
    |> validate_required([:user_id, :book_id, :passage_id, :body])
    |> validate_length(:body, min: 1, max: 500)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:book_id)
    |> foreign_key_constraint(:passage_id)
    |> unique_constraint(:passage_id)
  end
end
