defmodule Api.Usecases.InterestProfile.GetInterestProfile.GetInterestProfileUsecase do
  @moduledoc """
  A user's interest profile (keyword usage, most-used first) and the other
  users who most overlap with it ("similar readers").

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.InterestProfile.GetInterestProfile.GetInterestProfileUsecaseDto

  defstruct [:repository]

  def call(%GetInterestProfileUsecaseDto{user_id: user_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    {:ok,
     %{
       interest_profile: adapter.get_profile(user_id, adaptee),
       similar_readers: adapter.similar_readers(user_id, adaptee)
     }}
  end
end
