defmodule Api.Adapters.AccountsTest do
  use Api.DataCase, async: true

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Infrastructure.Repository.User.Postgres.User

  alias Api.Usecases.Follow.FollowUser.FollowUserUsecaseDto
  alias Api.Usecases.Follow.UnfollowUser.UnfollowUserUsecaseDto

  alias Api.Usecases.EmailConfirmation.ConfirmUser.ConfirmUserUsecaseDto

  alias Api.Usecases.EmailConfirmation.DeliverConfirmationInstructions.DeliverConfirmationInstructionsUsecaseDto

  alias Api.Usecases.PasswordReset.DeliverResetPasswordInstructions.DeliverResetPasswordInstructionsUsecaseDto

  alias Api.Usecases.PasswordReset.GetUserByResetPasswordToken.GetUserByResetPasswordTokenUsecaseDto

  alias Api.Usecases.PasswordReset.ResetUserPassword.ResetUserPasswordUsecaseDto

  alias Api.Usecases.Session.CreateSession.CreateSessionUsecaseDto
  alias Api.Usecases.Session.RefreshSession.RefreshSessionUsecaseDto
  alias Api.Usecases.Session.RevokeRefreshToken.RevokeRefreshTokenUsecaseDto

  alias Api.Usecases.User.GetUser.GetUserUsecaseDto
  alias Api.Usecases.User.GetUserByEmailAndPassword.GetUserByEmailAndPasswordUsecaseDto
  alias Api.Usecases.User.RegisterUser.RegisterUserUsecaseDto
  alias Api.Usecases.User.UpdateAvatar.UpdateAvatarUsecaseDto
  alias Api.Usecases.User.UpdateProfile.UpdateProfileUsecaseDto

  setup :verify_on_exit!

  @valid_attrs %{
    "email" => "reader@example.com",
    "password" => "supersecret",
    "name" => "Reader One"
  }

  defp register_user(attrs \\ %{}) do
    {:ok, user} =
      Accounts.register_user(%RegisterUserUsecaseDto{attrs: Map.merge(@valid_attrs, attrs)})

    user
  end

  defp create_session(user, remember_me) do
    Accounts.create_session(%CreateSessionUsecaseDto{user: user, remember_me: remember_me})
  end

  defp follow_user(follower, followee_id) do
    Accounts.follow_user(%FollowUserUsecaseDto{follower: follower, followee_id: followee_id})
  end

  defp unfollow_user(follower, followee_id) do
    Accounts.unfollow_user(%UnfollowUserUsecaseDto{follower: follower, followee_id: followee_id})
  end

  defp get_user(id, current_user \\ nil) do
    Accounts.get_user(%GetUserUsecaseDto{id: id, current_user: current_user})
  end

  describe "register_user/1" do
    test "creates a user with a hashed password and no confirmed_at" do
      assert {:ok, %User{} = user} =
               Accounts.register_user(%RegisterUserUsecaseDto{attrs: @valid_attrs})

      assert user.email == "reader@example.com"
      assert user.name == "Reader One"
      assert is_binary(user.hashed_password)
      assert user.hashed_password != "supersecret"
      assert is_nil(user.confirmed_at)
    end

    test "downcases the email" do
      attrs = %{@valid_attrs | "email" => "Reader@Example.com"}
      assert {:ok, user} = Accounts.register_user(%RegisterUserUsecaseDto{attrs: attrs})
      assert user.email == "reader@example.com"
    end

    test "rejects a duplicate email" do
      register_user()

      assert {:error, changeset} =
               Accounts.register_user(%RegisterUserUsecaseDto{attrs: @valid_attrs})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "rejects a short password" do
      attrs = %{@valid_attrs | "password" => "short"}
      assert {:error, changeset} = Accounts.register_user(%RegisterUserUsecaseDto{attrs: attrs})
      assert "should be at least 8 character(s)" in errors_on(changeset).password
    end

    test "requires a name" do
      attrs = Map.delete(@valid_attrs, "name")
      assert {:error, changeset} = Accounts.register_user(%RegisterUserUsecaseDto{attrs: attrs})
      assert "can't be blank" in errors_on(changeset).name
    end
  end

  describe "get_user_by_email_and_password/1" do
    test "returns the user when credentials match" do
      user = register_user()

      dto = %GetUserByEmailAndPasswordUsecaseDto{
        email: "reader@example.com",
        password: "supersecret"
      }

      assert Accounts.get_user_by_email_and_password(dto).id == user.id
    end

    test "returns nil when the password is wrong" do
      register_user()

      dto = %GetUserByEmailAndPasswordUsecaseDto{
        email: "reader@example.com",
        password: "wrong-password"
      }

      refute Accounts.get_user_by_email_and_password(dto)
    end

    test "returns nil when the user doesn't exist" do
      dto = %GetUserByEmailAndPasswordUsecaseDto{
        email: "nobody@example.com",
        password: "supersecret"
      }

      refute Accounts.get_user_by_email_and_password(dto)
    end
  end

  describe "update_profile/1" do
    test "updates name and bio" do
      user = register_user()
      attrs = %{"name" => "New Name", "bio" => "Avid reader"}

      assert {:ok, updated} =
               Accounts.update_profile(%UpdateProfileUsecaseDto{user: user, attrs: attrs})

      assert updated.name == "New Name"
      assert updated.bio == "Avid reader"
    end

    test "rejects a bio that is too long" do
      user = register_user()
      attrs = %{"bio" => String.duplicate("a", 501)}

      assert {:error, changeset} =
               Accounts.update_profile(%UpdateProfileUsecaseDto{user: user, attrs: attrs})

      assert "should be at most 500 character(s)" in errors_on(changeset).bio
    end

    test "sets the avatar to one of the fixed presets" do
      user = register_user()
      [preset | _] = User.avatar_choices()

      dto = %UpdateProfileUsecaseDto{user: user, attrs: %{"avatar_url" => preset}}
      assert {:ok, updated} = Accounts.update_profile(dto)
      assert updated.avatar_url == preset
    end

    test "rejects an avatar_url that isn't one of the presets" do
      user = register_user()

      dto = %UpdateProfileUsecaseDto{
        user: user,
        attrs: %{"avatar_url" => "https://evil.example/x.png"}
      }

      assert {:error, changeset} = Accounts.update_profile(dto)

      assert "must be one of the preset avatars" in errors_on(changeset).avatar_url
    end

    test "updating name/bio alone doesn't require an existing avatar_url to be a preset" do
      user = register_user()
      dto = %UpdateProfileUsecaseDto{user: user, attrs: %{"name" => "New Name"}}

      assert {:ok, updated} = Accounts.update_profile(dto)
      assert updated.avatar_url == nil
    end
  end

  describe "update_avatar/1" do
    test "stores the avatar via the configured object store and saves the returned URL" do
      user = register_user()

      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, binary, content_type ->
        assert id == user.id
        assert binary == "fake-bytes"
        assert content_type == "image/png"
        {:ok, "http://minio/avatars/#{id}.png"}
      end)

      dto = %UpdateAvatarUsecaseDto{user: user, binary: "fake-bytes", content_type: "image/png"}
      assert {:ok, updated} = Accounts.update_avatar(dto)
      assert updated.avatar_url == "http://minio/avatars/#{user.id}.png"
    end

    test "deletes the previous avatar once the new one is saved" do
      user = register_user()

      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, _content_type ->
        {:ok, "http://minio/avatars/#{id}-1.png"}
      end)

      {:ok, user} =
        Accounts.update_avatar(%UpdateAvatarUsecaseDto{
          user: user,
          binary: "first-bytes",
          content_type: "image/png"
        })

      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, _content_type ->
        {:ok, "http://minio/avatars/#{id}-2.png"}
      end)
      |> expect(:delete_avatar, fn url ->
        assert url == "http://minio/avatars/#{user.id}-1.png"
        :ok
      end)

      dto = %UpdateAvatarUsecaseDto{user: user, binary: "second-bytes", content_type: "image/png"}
      assert {:ok, updated} = Accounts.update_avatar(dto)
      assert updated.avatar_url == "http://minio/avatars/#{user.id}-2.png"
    end

    test "still succeeds if deleting the previous avatar fails" do
      user = register_user()

      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, _content_type ->
        {:ok, "http://minio/avatars/#{id}-1.png"}
      end)

      {:ok, user} =
        Accounts.update_avatar(%UpdateAvatarUsecaseDto{
          user: user,
          binary: "first-bytes",
          content_type: "image/png"
        })

      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, _content_type ->
        {:ok, "http://minio/avatars/#{id}-2.png"}
      end)
      |> expect(:delete_avatar, fn _url -> {:error, :not_found} end)

      dto = %UpdateAvatarUsecaseDto{user: user, binary: "second-bytes", content_type: "image/png"}
      assert {:ok, updated} = Accounts.update_avatar(dto)
      assert updated.avatar_url == "http://minio/avatars/#{user.id}-2.png"
    end
  end

  describe "email confirmation" do
    test "delivers instructions and confirms the user with the emailed token" do
      user = register_user()

      Api.MailerMock
      |> expect(:deliver_confirmation_instructions, fn delivered_user, url ->
        assert delivered_user.id == user.id
        send(self(), {:confirmation_url, url})
        {:ok, :delivered}
      end)

      deliver_dto = %DeliverConfirmationInstructionsUsecaseDto{
        user: user,
        confirmation_url_fun: fn token -> "http://web/confirm/#{token}" end
      }

      assert {:ok, :delivered} = Accounts.deliver_user_confirmation_instructions(deliver_dto)

      assert_receive {:confirmation_url, url}

      assert {:ok, confirmed} =
               Accounts.confirm_user(%ConfirmUserUsecaseDto{token: token_from_url(url)})

      assert confirmed.id == user.id
      assert confirmed.confirmed_at
    end

    test "rejects an already-confirmed user" do
      user = register_user()

      Api.MailerMock
      |> expect(:deliver_confirmation_instructions, fn _user, url ->
        send(self(), {:confirmation_url, url})
        {:ok, :delivered}
      end)

      deliver_dto = %DeliverConfirmationInstructionsUsecaseDto{
        user: user,
        confirmation_url_fun: &"http://web/confirm/#{&1}"
      }

      Accounts.deliver_user_confirmation_instructions(deliver_dto)
      assert_receive {:confirmation_url, url}

      {:ok, confirmed_user} =
        Accounts.confirm_user(%ConfirmUserUsecaseDto{token: token_from_url(url)})

      assert {:error, :already_confirmed} =
               Accounts.deliver_user_confirmation_instructions(%{
                 deliver_dto
                 | user: confirmed_user
               })
    end

    test "rejects an invalid token" do
      assert {:error, :invalid_token} =
               Accounts.confirm_user(%ConfirmUserUsecaseDto{token: "not-a-real-token"})
    end
  end

  describe "password reset" do
    test "delivers instructions and resets the password with the emailed token" do
      user = register_user()

      Api.MailerMock
      |> expect(:deliver_reset_password_instructions, fn delivered_user, url ->
        assert delivered_user.id == user.id
        send(self(), {:reset_url, url})
        {:ok, :delivered}
      end)

      deliver_dto = %DeliverResetPasswordInstructionsUsecaseDto{
        user: user,
        reset_url_fun: fn token -> "http://web/reset-password/#{token}" end
      }

      Accounts.deliver_user_reset_password_instructions(deliver_dto)

      assert_receive {:reset_url, url}
      token = token_from_url(url)

      fetched_user =
        Accounts.get_user_by_reset_password_token(%GetUserByResetPasswordTokenUsecaseDto{
          token: token
        })

      assert fetched_user.id == user.id

      reset_dto = %ResetUserPasswordUsecaseDto{
        user: fetched_user,
        attrs: %{"password" => "newsecret1"}
      }

      assert {:ok, updated} = Accounts.reset_user_password(reset_dto)

      password_dto = %GetUserByEmailAndPasswordUsecaseDto{
        email: user.email,
        password: "newsecret1"
      }

      assert Accounts.get_user_by_email_and_password(password_dto).id == updated.id

      refute Accounts.get_user_by_reset_password_token(%GetUserByResetPasswordTokenUsecaseDto{
               token: token
             })
    end

    test "revokes every existing session (refresh token) on success" do
      user = register_user()
      {:ok, _access_token, refresh_token_a} = create_session(user, false)
      {:ok, _access_token, refresh_token_b} = create_session(user, true)

      reset_dto = %ResetUserPasswordUsecaseDto{user: user, attrs: %{"password" => "newsecret1"}}
      {:ok, _updated} = Accounts.reset_user_password(reset_dto)

      assert :error =
               Accounts.refresh_session(%RefreshSessionUsecaseDto{refresh_token: refresh_token_a})

      assert :error =
               Accounts.refresh_session(%RefreshSessionUsecaseDto{refresh_token: refresh_token_b})
    end

    test "rejects an unknown token" do
      dto = %GetUserByResetPasswordTokenUsecaseDto{token: "not-a-real-token"}
      refute Accounts.get_user_by_reset_password_token(dto)
    end
  end

  describe "sessions" do
    test "create_session/1 issues an access token and a refresh token" do
      user = register_user()
      assert {:ok, access_token, refresh_token} = create_session(user, false)
      assert is_binary(access_token)
      assert is_binary(refresh_token)
    end

    test "refresh_session/1 rotates a valid refresh token" do
      user = register_user()
      {:ok, _access_token, refresh_token} = create_session(user, false)

      assert {:ok, new_access_token, new_refresh_token, false} =
               Accounts.refresh_session(%RefreshSessionUsecaseDto{refresh_token: refresh_token})

      assert new_refresh_token != refresh_token
      assert {:ok, claims} = Api.Infrastructure.Guardian.decode_and_verify(new_access_token)
      assert claims["sub"] == to_string(user.id)

      # the old refresh token was consumed and can't be reused
      assert :error =
               Accounts.refresh_session(%RefreshSessionUsecaseDto{refresh_token: refresh_token})
    end

    test "refresh_session/1 carries the original remember_me flag forward" do
      user = register_user()
      {:ok, _access_token, refresh_token} = create_session(user, true)

      assert {:ok, _access_token, _new_refresh_token, true} =
               Accounts.refresh_session(%RefreshSessionUsecaseDto{refresh_token: refresh_token})
    end

    test "refresh_session/1 returns :error for an unknown token" do
      assert :error = Accounts.refresh_session(%RefreshSessionUsecaseDto{refresh_token: "bogus"})
    end

    test "revoke_refresh_token/1 invalidates the token" do
      user = register_user()
      {:ok, _access_token, refresh_token} = create_session(user, false)

      assert :ok =
               Accounts.revoke_refresh_token(%RevokeRefreshTokenUsecaseDto{
                 refresh_token: refresh_token
               })

      assert :error =
               Accounts.refresh_session(%RefreshSessionUsecaseDto{refresh_token: refresh_token})
    end
  end

  describe "follow_user/1" do
    test "follows a user" do
      follower = register_user()
      followee = register_user(%{"email" => "followee@example.com"})

      assert {:ok, %{following: true}} = follow_user(follower, followee.id)
      assert get_user(followee.id, follower).followed_by_user == true
    end

    test "following twice is idempotent" do
      follower = register_user()
      followee = register_user(%{"email" => "followee2@example.com"})

      assert {:ok, %{following: true}} = follow_user(follower, followee.id)
      assert {:ok, %{following: true}} = follow_user(follower, followee.id)
    end

    test "rejects following yourself" do
      user = register_user()
      assert {:error, :cannot_follow_self} = follow_user(user, user.id)
    end

    test "returns not_found for a missing or invalid followee id" do
      follower = register_user()

      assert {:error, :not_found} = follow_user(follower, Ecto.UUID.generate())
      assert {:error, :not_found} = follow_user(follower, "not-a-uuid")
    end
  end

  describe "unfollow_user/1" do
    test "unfollows a previously-followed user" do
      follower = register_user()
      followee = register_user(%{"email" => "followee3@example.com"})

      assert {:ok, %{following: true}} = follow_user(follower, followee.id)
      assert {:ok, %{following: false}} = unfollow_user(follower, followee.id)
      assert get_user(followee.id, follower).followed_by_user == false
    end

    test "unfollowing a user that wasn't followed is a no-op" do
      follower = register_user()
      followee = register_user(%{"email" => "followee4@example.com"})

      assert {:ok, %{following: false}} = unfollow_user(follower, followee.id)
    end
  end

  describe "get_user/1 followed_by_user annotation" do
    test "flags followed_by_user per the given current_user" do
      follower = register_user()
      followee = register_user(%{"email" => "followee5@example.com"})

      assert {:ok, _} = follow_user(follower, followee.id)

      assert get_user(followee.id, follower).followed_by_user == true
      assert get_user(followee.id, followee).followed_by_user == false
      assert get_user(followee.id).followed_by_user == false
    end
  end

  defp token_from_url(url), do: url |> String.split("/") |> List.last()
end
