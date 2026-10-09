defmodule Api.Domain.Connection do
  @moduledoc """
  Pure business-rule entity for a typed link between two posts. Holds no
  knowledge of Ecto, Postgres, or any other persistence detail.

  `connected_post` is always "the other post" relative to whichever post
  this connection was fetched for — callers never need to know whether this
  connection was originally created from that post's side or the other's.
  """

  defstruct [:id, :relationship_type, :connected_post, :inserted_at]

  @type t :: %__MODULE__{
          id: String.t(),
          relationship_type: String.t(),
          connected_post: Api.Domain.Post.t(),
          inserted_at: DateTime.t() | nil
        }
end
