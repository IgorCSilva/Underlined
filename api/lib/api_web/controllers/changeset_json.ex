defmodule ApiWeb.ChangesetJSON do
  def error(%{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end

  defp translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(ApiWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ApiWeb.Gettext, "errors", msg, opts)
    end
  end
end
