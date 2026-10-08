defmodule Api.Domain.GraphNode do
  @moduledoc """
  A single node in a `Api.Domain.Graph`: either a post (`type: "post"`,
  `post` populated) or a keyword (`type: "keyword"`, `keyword` populated).
  """

  defstruct [:id, :type, :post, :keyword]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          type: String.t(),
          post: Api.Domain.Post.t() | nil,
          keyword: Api.Domain.Keyword.t() | nil
        }
end
