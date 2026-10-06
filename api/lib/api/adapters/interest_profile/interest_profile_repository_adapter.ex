defmodule Api.Adapters.InterestProfile.InterestProfileRepositoryAdapter do
  @moduledoc """
  Adapts the interest-profile repository (the adaptee) to the domain:
  calls it for the database entities, then converts any nested user
  entity into the pure Api.Domain.User business entity.
  """

  alias Api.Adapters.User.UserRepositoryAdapter

  def get_profile(user_id, adaptee), do: adaptee.get_profile(user_id)

  def similar_readers(user_id, adaptee) do
    adaptee.similar_readers(user_id)
    |> Enum.map(fn %{user: db_user, shared_score: shared_score} ->
      %{user: UserRepositoryAdapter.to_domain(db_user), shared_score: shared_score}
    end)
  end
end
