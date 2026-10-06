defmodule Api.Adapters.InterestProfiles do
  @moduledoc """
  Facade over the interest-profile usecase.

  Callers build the DTO the target usecase expects and pass it in; this
  module only routes each DTO to its usecase.
  """

  alias Api.Usecases.InterestProfile.GetInterestProfile.GetInterestProfileUsecase

  def get_interest_profile(dto) do
    GetInterestProfileUsecase.call(dto, %GetInterestProfileUsecase{repository: interest_profile_repository()})
  end

  defp interest_profile_repository,
    do: Application.get_env(:api, :interest_profile_repository) |> Map.new()
end
