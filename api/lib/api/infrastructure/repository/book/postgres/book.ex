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
    field :genres, {:array, :string}, default: []
    field :series_name, :string
    field :series_position, :integer

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(book, attrs) do
    book
    |> cast(attrs, [:title, :author, :cover_url, :genres, :series_name, :series_position])
    |> update_change(:cover_url, &blank_to_nil/1)
    |> update_change(:genres, &normalize_genres/1)
    |> update_change(:series_name, &blank_to_nil/1)
    |> validate_required([:title, :author])
    |> validate_length(:title, min: 1, max: 80)
    |> validate_length(:author, min: 1, max: 80)
    |> validate_length(:series_name, max: 120)
    |> validate_number(:series_position, greater_than: 0)
    |> maybe_validate_cover_url()
    |> validate_genres()
    |> validate_series_position_requires_series_name()
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp normalize_genres(nil), do: []

  defp normalize_genres(genres) do
    genres
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp validate_genres(changeset) do
    validate_change(changeset, :genres, fn :genres, genres ->
      if Enum.any?(genres, &(String.length(&1) > 60)) do
        [genres: gettext("each genre must be at most 60 characters")]
      else
        []
      end
    end)
  end

  defp maybe_validate_cover_url(changeset) do
    if get_change(changeset, :cover_url) do
      validate_format(changeset, :cover_url, ~r/^https?:\/\//,
        message: gettext("must be a valid http(s) URL")
      )
    else
      changeset
    end
  end

  defp validate_series_position_requires_series_name(changeset) do
    if is_nil(get_field(changeset, :series_name)) and
         not is_nil(get_field(changeset, :series_position)) do
      add_error(
        changeset,
        :series_position,
        gettext("can only be set when the book is part of a series")
      )
    else
      changeset
    end
  end
end
