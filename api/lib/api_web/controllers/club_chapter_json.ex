defmodule ApiWeb.ClubChapterJSON do
  alias Api.Domain.ClubChapter

  def index(%{chapters: chapters}), do: %{data: Enum.map(chapters, &data/1)}
  def show(%{chapter: chapter}), do: %{data: data(chapter)}

  def data(%ClubChapter{} = chapter) do
    %{
      id: chapter.id,
      position: chapter.position,
      label: chapter.label,
      current: chapter.current,
      inserted_at: chapter.inserted_at
    }
  end
end
