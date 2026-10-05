defmodule Api.Adapters.Accounts do
  @moduledoc """
  Facade over the accounts usecases: registration, authentication,
  sessions, email confirmation/password reset, and profile management.

  Callers build the DTO the target usecase expects and pass it in; this
  module only routes each DTO to its usecase.
  """

  alias Api.Usecases.EmailConfirmation.ConfirmUser.ConfirmUserUsecase

  alias Api.Usecases.EmailConfirmation.DeliverConfirmationInstructions.DeliverConfirmationInstructionsUsecase

  alias Api.Usecases.Follow.FollowUser.FollowUserUsecase
  alias Api.Usecases.Follow.UnfollowUser.UnfollowUserUsecase

  alias Api.Usecases.PasswordReset.DeliverResetPasswordInstructions.DeliverResetPasswordInstructionsUsecase
  alias Api.Usecases.PasswordReset.GetUserByResetPasswordToken.GetUserByResetPasswordTokenUsecase
  alias Api.Usecases.PasswordReset.ResetUserPassword.ResetUserPasswordUsecase

  alias Api.Usecases.Session.CreateSession.CreateSessionUsecase
  alias Api.Usecases.Session.RefreshSession.RefreshSessionUsecase
  alias Api.Usecases.Session.RevokeAllRefreshTokens.RevokeAllRefreshTokensUsecase
  alias Api.Usecases.Session.RevokeRefreshToken.RevokeRefreshTokenUsecase

  alias Api.Usecases.User.GetUser.GetUserUsecase
  alias Api.Usecases.User.GetUserByEmail.GetUserByEmailUsecase
  alias Api.Usecases.User.GetUserByEmailAndPassword.GetUserByEmailAndPasswordUsecase
  alias Api.Usecases.User.GetUserOrRaise.GetUserOrRaiseUsecase
  alias Api.Usecases.User.RegisterUser.RegisterUserUsecase
  alias Api.Usecases.User.UpdateAvatar.UpdateAvatarUsecase
  alias Api.Usecases.User.UpdateProfile.UpdateProfileUsecase

  ## Users

  def get_user(dto) do
    GetUserUsecase.call(dto, %GetUserUsecase{repository: user_repository()})
  end

  def get_user!(dto), do: GetUserOrRaiseUsecase.call(dto)
  def get_user_by_email(dto), do: GetUserByEmailUsecase.call(dto)
  def get_user_by_email_and_password(dto), do: GetUserByEmailAndPasswordUsecase.call(dto)
  def register_user(dto) do
    RegisterUserUsecase.call(dto, %RegisterUserUsecase{
      community_health_enqueuer: community_health_enqueuer()
    })
  end

  def update_profile(dto) do
    UpdateProfileUsecase.call(dto, %UpdateProfileUsecase{
      community_health_enqueuer: community_health_enqueuer()
    })
  end
  def update_avatar(dto), do: UpdateAvatarUsecase.call(dto)

  ## Follows

  def follow_user(dto) do
    FollowUserUsecase.call(dto, %FollowUserUsecase{repository: follow_repository()})
  end

  def unfollow_user(dto) do
    UnfollowUserUsecase.call(dto, %UnfollowUserUsecase{repository: follow_repository()})
  end

  ## Email confirmation

  def deliver_user_confirmation_instructions(dto) do
    DeliverConfirmationInstructionsUsecase.call(dto, %DeliverConfirmationInstructionsUsecase{
      repository: user_token_repository()
    })
  end

  def confirm_user(dto) do
    ConfirmUserUsecase.call(dto, %ConfirmUserUsecase{repository: user_token_repository()})
  end

  ## Password reset

  def deliver_user_reset_password_instructions(dto) do
    DeliverResetPasswordInstructionsUsecase.call(dto, %DeliverResetPasswordInstructionsUsecase{
      repository: user_token_repository()
    })
  end

  def get_user_by_reset_password_token(dto) do
    GetUserByResetPasswordTokenUsecase.call(dto, %GetUserByResetPasswordTokenUsecase{
      repository: user_token_repository()
    })
  end

  def reset_user_password(dto) do
    ResetUserPasswordUsecase.call(dto, %ResetUserPasswordUsecase{repository: user_repository()})
  end

  ## Sessions

  def create_session(dto) do
    CreateSessionUsecase.call(dto, %CreateSessionUsecase{repository: refresh_token_repository()})
  end

  def refresh_session(dto) do
    RefreshSessionUsecase.call(dto, %RefreshSessionUsecase{
      repository: refresh_token_repository()
    })
  end

  def revoke_refresh_token(dto) do
    RevokeRefreshTokenUsecase.call(dto, %RevokeRefreshTokenUsecase{
      repository: refresh_token_repository()
    })
  end

  def revoke_all_refresh_tokens(dto) do
    RevokeAllRefreshTokensUsecase.call(dto, %RevokeAllRefreshTokensUsecase{
      repository: refresh_token_repository()
    })
  end

  defp user_repository, do: Application.get_env(:api, :user_repository) |> Map.new()
  defp follow_repository, do: Application.get_env(:api, :follow_repository) |> Map.new()

  defp user_token_repository,
    do: Application.get_env(:api, :user_token_repository) |> Map.new()

  defp refresh_token_repository,
    do: Application.get_env(:api, :refresh_token_repository) |> Map.new()

  defp community_health_enqueuer,
    do:
      Application.get_env(
        :api,
        :community_health_enqueuer,
        &Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker.enqueue/1
      )
end
