defmodule Api.Infrastructure.Repository.Book.Postgres.Book do
  @moduledoc """
  Postgres-backed book entity (Ecto schema). This is database structure, not
  a business-rule entity — it belongs to infrastructure, not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import ApiWeb.Gettext

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "books" do
    field :title, :string
    field :author, :string
    field :cover_url, :string

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(book, attrs) do
    book
    |> cast(attrs, [:title, :author, :cover_url])
    |> update_change(:cover_url, fn
      "" -> nil
      value -> value
    end)
    |> validate_required([:title, :author])
    |> validate_length(:title, min: 1, max: 300)
    |> validate_length(:author, min: 1, max: 300)
    |> maybe_validate_cover_url()
  end

  defp maybe_validate_cover_url(changeset) do
    if get_change(changeset, :cover_url) do
      validate_format(changeset, :cover_url, ~r/^https?:\/\//, message: gettext("must be a valid http(s) URL"))
    else
      changeset
    end
  end
end
