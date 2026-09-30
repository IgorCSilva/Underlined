defmodule ApiWeb.FallbackController do
  use ApiWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: ApiWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :invalid_token}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "invalid or expired token"}})
  end

  def call(conn, {:error, :already_confirmed}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "account already confirmed"}})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{errors: %{detail: "not found"}})
  end

  def call(conn, {:error, :invalid_upload}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "must be a PNG, JPEG, or WebP image"}})
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> json(%{errors: %{detail: "forbidden"}})
  end

  # Catch-all for unexpected port failures (e.g. the object store being
  # unreachable) so they surface as a clean 502 instead of a 500 crash page.
  def call(conn, {:error, reason}) do
    require Logger
    Logger.error("Unhandled action error: #{inspect(reason)}")

    conn
    |> put_status(:bad_gateway)
    |> json(%{errors: %{detail: "an upstream service failed, please try again"}})
  end
end
