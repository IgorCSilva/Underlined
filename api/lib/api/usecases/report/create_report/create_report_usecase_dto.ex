defmodule Api.Usecases.Report.CreateReport.CreateReportUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Report.CreateReport.CreateReportUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :attrs]
  defstruct [:user, :attrs]

  @type t :: %__MODULE__{user: %User{}, attrs: map()}
end
