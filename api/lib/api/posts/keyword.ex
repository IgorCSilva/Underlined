defmodule Api.Posts.Keyword do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "keywords" do
    field :name, :string

    many_to_many :posts, Api.Posts.Post, join_through: "post_keywords"

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(keyword, attrs) do
    keyword
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 40)
    |> unique_constraint(:name)
  end
end
