defmodule ApiWeb.ReportJSON do
  def reasons(%{result: %{rules: rules, community_health_available: available}}) do
    %{data: %{rules: rules, community_health_available: available}}
  end

  def create(%{status: status}), do: %{data: %{status: status}}
end
