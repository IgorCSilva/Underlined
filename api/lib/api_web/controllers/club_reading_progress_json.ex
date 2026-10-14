defmodule ApiWeb.ClubReadingProgressJSON do
  alias Api.Domain.ClubReadingProgress
  alias ApiWeb.ClubChapterJSON

  def show(%{progress: progress}), do: %{data: data(progress)}

  def data(%ClubReadingProgress{} = progress) do
    %{chapter: progress.chapter && ClubChapterJSON.data(progress.chapter)}
  end
end
