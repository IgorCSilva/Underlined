defmodule Api.Infra.S3ObjectStore do
  @moduledoc """
  ObjectStorePort implementation backed by S3-compatible storage (MinIO in dev, R2 in prod).

  Credentials/endpoint come from the standard `:ex_aws`/`:ex_aws, :s3` config; only the
  bucket name and the public URL prefix are looked up here.
  """

  @behaviour Api.Ports.ObjectStorePort

  @impl true
  def put_avatar(user_id, binary, content_type) do
    bucket = config(:bucket)
    ext = extension_for(content_type)
    key = "#{user_id}-#{System.unique_integer([:positive])}#{ext}"

    request =
      ExAws.S3.put_object(bucket, key, binary,
        content_type: content_type,
        acl: :public_read
      )

    case ExAws.request(request) do
      {:ok, _} -> {:ok, public_url(key)}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def delete_avatar(url) do
    case key_from_url(url) do
      {:ok, key} ->
        case ExAws.request(ExAws.S3.delete_object(config(:bucket), key)) do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, reason}
        end

      :error ->
        {:error, :invalid_url}
    end
  end

  defp public_url(key) do
    "#{config(:public_endpoint)}/#{config(:bucket)}/#{key}"
  end

  # Only ever deletes objects whose URL we ourselves generated (same
  # endpoint + bucket prefix) — never an arbitrary caller-supplied URL.
  defp key_from_url(url) do
    prefix = "#{config(:public_endpoint)}/#{config(:bucket)}/"

    if String.starts_with?(url, prefix) do
      {:ok, String.replace_prefix(url, prefix, "")}
    else
      :error
    end
  end

  defp extension_for("image/png"), do: ".png"
  defp extension_for("image/jpeg"), do: ".jpg"
  defp extension_for("image/webp"), do: ".webp"
  defp extension_for(_other), do: ""

  defp config(key), do: Application.fetch_env!(:api, __MODULE__) |> Keyword.fetch!(key)
end
