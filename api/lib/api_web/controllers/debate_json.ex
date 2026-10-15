defmodule ApiWeb.DebateJSON do
  alias Api.Domain.Debate

  def show(%{debate: debate}), do: %{data: data(debate)}

  def data(%Debate{} = debate) do
    %{
      id: debate.id,
      relationship_type: debate.relationship_type,
      inserted_at: debate.inserted_at,
      post_a: ApiWeb.PostJSON.data(debate.post_a),
      post_b: ApiWeb.PostJSON.data(debate.post_b)
    }
  end
end
