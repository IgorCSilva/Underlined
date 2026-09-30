defmodule Api.Ports.ObjectStorePort do
  @moduledoc "Behaviour for storing user-uploaded objects (e.g. avatars)."

  @callback put_avatar(user_id :: integer(), binary :: binary(), content_type :: String.t()) ::
              {:ok, url :: String.t()} | {:error, term()}

  @callback delete_avatar(url :: String.t()) :: :ok | {:error, term()}
end
