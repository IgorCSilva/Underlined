defmodule ApiWeb.ReportController do
  use ApiWeb, :controller

  alias Api.Adapters.Posts
  alias Api.Usecases.Report.CreateReport.CreateReportUsecaseDto
  alias Api.Usecases.Report.ListReportReasons.ListReportReasonsUsecaseDto

  action_fallback ApiWeb.FallbackController

  def reasons(conn, _params) do
    with {:ok, result} <- Posts.list_report_reasons(%ListReportReasonsUsecaseDto{}) do
      render(conn, :reasons, result: result)
    end
  end

  def create(conn, %{"report" => report_params}) do
    with {:ok, _} <-
           Posts.create_report(%CreateReportUsecaseDto{
             user: current_user(conn),
             attrs: report_params
           }) do
      conn
      |> put_status(:created)
      |> render(:create, status: :queued)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
