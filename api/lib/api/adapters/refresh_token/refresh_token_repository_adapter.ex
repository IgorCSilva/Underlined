defmodule Api.Adapters.RefreshToken.RefreshTokenRepositoryAdapter do
  @moduledoc """
  Adapts a refresh-token repository (the adaptee) to the usecase layer.
  """

  def insert(user, remember_me?, adaptee), do: adaptee.insert(user, remember_me?)

  def find_valid(token, adaptee), do: adaptee.find_valid(token)

  def delete(refresh_token, adaptee), do: adaptee.delete(refresh_token)

  def delete_by_hash(token, adaptee), do: adaptee.delete_by_hash(token)

  def delete_all_for_user(user, adaptee), do: adaptee.delete_all_for_user(user)
end
