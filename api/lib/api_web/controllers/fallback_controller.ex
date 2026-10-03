defmodule ApiWeb.FallbackController do
  use ApiWeb, :controller
  import ApiWeb.Gettext

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: ApiWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :invalid_token}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: gettext("invalid or expired token"), code: "invalid_token"}})
  end

  def call(conn, {:error, :already_confirmed}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: gettext("account already confirmed"), code: "already_confirmed"}})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{errors: %{detail: gettext("not found"), code: "not_found"}})
  end

  def call(conn, {:error, :invalid_upload}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      errors: %{detail: gettext("must be a PNG, JPEG, or WebP image"), code: "invalid_upload"}
    })
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> json(%{errors: %{detail: gettext("forbidden"), code: "forbidden"}})
  end

  def call(conn, {:error, :cannot_follow_self}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: gettext("can't follow yourself"), code: "cannot_follow_self"}})
  end

  def call(conn, {:error, :invalid_parent}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      errors: %{
        detail: gettext("can only reply to a top-level comment"),
        code: "invalid_parent"
      }
    })
  end

  def call(conn, {:error, :rate_limited}) do
    conn
    |> put_status(:too_many_requests)
    |> json(%{
      errors: %{
        detail: gettext("you're commenting too fast, please slow down"),
        code: "rate_limited"
      }
    })
  end

  # Catch-all for unexpected port failures (e.g. the object store being
  # unreachable) so they surface as a clean 502 instead of a 500 crash page.
  def call(conn, {:error, reason}) do
    require Logger
    Logger.error("Unhandled action error: #{inspect(reason)}")

    conn
    |> put_status(:bad_gateway)
    |> json(%{
      errors: %{
        detail: gettext("an upstream service failed, please try again"),
        code: "upstream_error"
      }
    })
  end
end
