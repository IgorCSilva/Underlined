defmodule Api.Adapters.UserToken.UserTokenRepositoryAdapter do
  @moduledoc """
  Adapts a user-token repository (the adaptee) to the usecase layer.
  """

  def create_email_token(user, context, adaptee), do: adaptee.create_email_token(user, context)

  def verify_email_token(token, context, adaptee), do: adaptee.verify_email_token(token, context)

  def confirm_user(user, adaptee), do: adaptee.confirm_user(user)
end
