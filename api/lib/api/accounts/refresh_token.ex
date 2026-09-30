defmodule Api.Accounts.RefreshToken do
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @rand_size 32
  @session_validity_in_days 1
  @remember_me_validity_in_days 30

  schema "refresh_tokens" do
    field :token_hash, :string
    field :expires_at, :utc_datetime
    field :remember_me, :boolean, default: false
    belongs_to :user, Api.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Builds a new refresh token for the given user. Returns the plaintext token
  (to hand to the client) and the schema struct holding only its hash.
  """
  def build(user, remember_me?) do
    token = :crypto.strong_rand_bytes(@rand_size) |> Base.url_encode64(padding: false)
    days = if remember_me?, do: @remember_me_validity_in_days, else: @session_validity_in_days

    expires_at =
      DateTime.utc_now()
      |> DateTime.add(days, :day)
      |> DateTime.truncate(:second)

    {token,
     %__MODULE__{
       token_hash: hash(token),
       expires_at: expires_at,
       remember_me: remember_me?,
       user_id: user.id
     }}
  end

  def hash(token), do: :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)

  def valid_query(token) do
    from rt in __MODULE__,
      join: u in assoc(rt, :user),
      where: rt.token_hash == ^hash(token) and rt.expires_at > ^DateTime.utc_now(),
      select: {rt, u}
  end

  def by_hash_query(token) do
    from rt in __MODULE__, where: rt.token_hash == ^hash(token)
  end

  def by_user_query(user) do
    from rt in __MODULE__, where: rt.user_id == ^user.id
  end
end
