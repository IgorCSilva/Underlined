defmodule Api.Infrastructure.Repository.Answer.Postgres.Answer do
  @moduledoc """
  Postgres-backed answer entity (Ecto schema). This is database structure,
  not a business-rule entity — it belongs to infrastructure, not the
  domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Question.Postgres.Question
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "answers" do
    field :body, :string
    field :is_best, :boolean, default: false

    belongs_to :question, Question
    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(answer, attrs) do
    answer
    |> cast(attrs, [:question_id, :user_id, :body])
    |> validate_required([:question_id, :user_id, :body])
    |> validate_length(:body, min: 1, max: 500)
    |> foreign_key_constraint(:question_id)
    |> foreign_key_constraint(:user_id)
  end
end
