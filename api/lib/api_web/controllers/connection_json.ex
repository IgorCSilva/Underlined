defmodule ApiWeb.ConnectionJSON do
  alias Api.Domain.Connection

  def index(%{connections: connections}), do: %{data: Enum.map(connections, &data/1)}
  def show(%{connection: connection}), do: %{data: data(connection)}

  def data(%Connection{} = connection) do
    %{
      id: connection.id,
      relationship_type: connection.relationship_type,
      inserted_at: connection.inserted_at,
      connected_post: ApiWeb.PostJSON.data(connection.connected_post)
    }
  end
end
