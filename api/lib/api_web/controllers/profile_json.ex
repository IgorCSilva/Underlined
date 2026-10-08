defmodule ApiWeb.ProfileJSON do
  alias ApiWeb.UserJSON

  def show(%{user: user}), do: %{data: UserJSON.data(user)}

  def graph(%{graph: graph}), do: ApiWeb.GraphJSON.show(%{graph: graph})

  def interests(%{result: %{interest_profile: interest_profile, similar_readers: similar_readers}}) do
    %{
      data: %{
        interest_profile: interest_profile,
        similar_readers:
          Enum.map(similar_readers, fn %{user: user, shared_score: shared_score} ->
            %{id: user.id, name: user.name, avatar_url: user.avatar_url, shared_score: shared_score}
          end)
      }
    }
  end

  def community_health(%{
        result: %{
          reputation_level: reputation_level,
          trust_level: trust_level,
          community_health_available: available
        }
      }) do
    %{
      data: %{
        reputation_level: reputation_level,
        trust_level: trust_level,
        community_health_available: available
      }
    }
  end
end
