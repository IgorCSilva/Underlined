defmodule Api.Infrastructure.Repository.User.Postgres.User do
  @moduledoc """
  Postgres-backed user entity (Ecto schema). This is database structure, not
  a business-rule entity — it belongs to infrastructure, not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :name, :string
    field :bio, :string
    field :avatar_url, :string
    field :confirmed_at, :utc_datetime
    field :enabled, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for registering a new user: validates email/password/name and hashes the password.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :name])
    |> validate_email()
    |> validate_password()
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
  end

  # Real avatar uploads aren't wired up yet, so profile edits can only pick
  # one of these fixed preset images (served from web/public/avatars) instead.
  @avatar_choices for n <- 1..10, do: "/avatars/avatar#{n}.jpg"

  def avatar_choices, do: @avatar_choices

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :bio, :avatar_url])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:bio, max: 500)
    |> validate_inclusion(:avatar_url, @avatar_choices, message: "must be one of the preset avatars")
  end

  def avatar_changeset(user, avatar_url) do
    change(user, avatar_url: avatar_url)
  end

  def confirm_changeset(user) do
    change(user, confirmed_at: DateTime.truncate(DateTime.utc_now(), :second))
  end

  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> update_change(:email, &String.downcase/1)
    |> unsafe_validate_unique(:email, Api.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> maybe_hash_password()
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc "Verifies the given password against the user's hashed password."
  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_user, _password) do
    Bcrypt.no_user_verify()
    false
  end

  def confirmed?(%__MODULE__{confirmed_at: nil}), do: false
  def confirmed?(%__MODULE__{}), do: true

  def enabled?(%__MODULE__{enabled: enabled}), do: enabled
end
