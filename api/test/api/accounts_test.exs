defmodule Api.AccountsTest do
  use Api.DataCase, async: true

  import Mox

  alias Api.Accounts
  alias Api.Accounts.User

  setup :verify_on_exit!

  @valid_attrs %{
    "email" => "reader@example.com",
    "password" => "supersecret",
    "name" => "Reader One"
  }

  defp register_user(attrs \\ %{}) do
    {:ok, user} = Accounts.register_user(Map.merge(@valid_attrs, attrs))
    user
  end

  describe "register_user/1" do
    test "creates a user with a hashed password and no confirmed_at" do
      assert {:ok, %User{} = user} = Accounts.register_user(@valid_attrs)
      assert user.email == "reader@example.com"
      assert user.name == "Reader One"
      assert is_binary(user.hashed_password)
      assert user.hashed_password != "supersecret"
      assert is_nil(user.confirmed_at)
    end

    test "downcases the email" do
      assert {:ok, user} = Accounts.register_user(%{@valid_attrs | "email" => "Reader@Example.com"})
      assert user.email == "reader@example.com"
    end

    test "rejects a duplicate email" do
      register_user()
      assert {:error, changeset} = Accounts.register_user(@valid_attrs)
      assert "has already been taken" in errors_on(changeset).email
    end

    test "rejects a short password" do
      assert {:error, changeset} = Accounts.register_user(%{@valid_attrs | "password" => "short"})
      assert "should be at least 8 character(s)" in errors_on(changeset).password
    end

    test "requires a name" do
      assert {:error, changeset} = Accounts.register_user(Map.delete(@valid_attrs, "name"))
      assert "can't be blank" in errors_on(changeset).name
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "returns the user when credentials match" do
      user = register_user()
      assert Accounts.get_user_by_email_and_password("reader@example.com", "supersecret").id == user.id
    end

    test "returns nil when the password is wrong" do
      register_user()
      refute Accounts.get_user_by_email_and_password("reader@example.com", "wrong-password")
    end

    test "returns nil when the user doesn't exist" do
      refute Accounts.get_user_by_email_and_password("nobody@example.com", "supersecret")
    end
  end

  describe "update_profile/2" do
    test "updates name and bio" do
      user = register_user()
      assert {:ok, updated} = Accounts.update_profile(user, %{"name" => "New Name", "bio" => "Avid reader"})
      assert updated.name == "New Name"
      assert updated.bio == "Avid reader"
    end

    test "rejects a bio that is too long" do
      user = register_user()
      assert {:error, changeset} = Accounts.update_profile(user, %{"bio" => String.duplicate("a", 501)})
      assert "should be at most 500 character(s)" in errors_on(changeset).bio
    end

    test "sets the avatar to one of the fixed presets" do
      user = register_user()
      [preset | _] = User.avatar_choices()

      assert {:ok, updated} = Accounts.update_profile(user, %{"avatar_url" => preset})
      assert updated.avatar_url == preset
    end

    test "rejects an avatar_url that isn't one of the presets" do
      user = register_user()

      assert {:error, changeset} =
               Accounts.update_profile(user, %{"avatar_url" => "https://evil.example/x.png"})

      assert "must be one of the preset avatars" in errors_on(changeset).avatar_url
    end

    test "updating name/bio alone doesn't require an existing avatar_url to be a preset" do
      user = register_user()
      assert {:ok, updated} = Accounts.update_profile(user, %{"name" => "New Name"})
      assert updated.avatar_url == nil
    end
  end

  describe "update_avatar/3" do
    test "stores the avatar via the configured object store and saves the returned URL" do
      user = register_user()

      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, binary, content_type ->
        assert id == user.id
        assert binary == "fake-bytes"
        assert content_type == "image/png"
        {:ok, "http://minio/avatars/#{id}.png"}
      end)

      assert {:ok, updated} = Accounts.update_avatar(user, "fake-bytes", "image/png")
      assert updated.avatar_url == "http://minio/avatars/#{user.id}.png"
    end

    test "deletes the previous avatar once the new one is saved" do
      user = register_user()

      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, _content_type ->
        {:ok, "http://minio/avatars/#{id}-1.png"}
      end)

      {:ok, user} = Accounts.update_avatar(user, "first-bytes", "image/png")

      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, _content_type ->
        {:ok, "http://minio/avatars/#{id}-2.png"}
      end)
      |> expect(:delete_avatar, fn url ->
        assert url == "http://minio/avatars/#{user.id}-1.png"
        :ok
      end)

      assert {:ok, updated} = Accounts.update_avatar(user, "second-bytes", "image/png")
      assert updated.avatar_url == "http://minio/avatars/#{user.id}-2.png"
    end

    test "still succeeds if deleting the previous avatar fails" do
      user = register_user()

      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, _content_type ->
        {:ok, "http://minio/avatars/#{id}-1.png"}
      end)

      {:ok, user} = Accounts.update_avatar(user, "first-bytes", "image/png")

      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, _content_type ->
        {:ok, "http://minio/avatars/#{id}-2.png"}
      end)
      |> expect(:delete_avatar, fn _url -> {:error, :not_found} end)

      assert {:ok, updated} = Accounts.update_avatar(user, "second-bytes", "image/png")
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

      assert {:ok, :delivered} =
               Accounts.deliver_user_confirmation_instructions(user, fn token ->
                 "http://web/confirm/#{token}"
               end)

      assert_receive {:confirmation_url, url}
      assert {:ok, confirmed} = Accounts.confirm_user(token_from_url(url))
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

      Accounts.deliver_user_confirmation_instructions(user, &"http://web/confirm/#{&1}")
      assert_receive {:confirmation_url, url}
      {:ok, confirmed_user} = Accounts.confirm_user(token_from_url(url))

      assert {:error, :already_confirmed} =
               Accounts.deliver_user_confirmation_instructions(confirmed_user, &"http://web/confirm/#{&1}")
    end

    test "rejects an invalid token" do
      assert {:error, :invalid_token} = Accounts.confirm_user("not-a-real-token")
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

      Accounts.deliver_user_reset_password_instructions(user, fn token ->
        "http://web/reset-password/#{token}"
      end)

      assert_receive {:reset_url, url}
      token = token_from_url(url)

      fetched_user = Accounts.get_user_by_reset_password_token(token)
      assert fetched_user.id == user.id

      assert {:ok, updated} = Accounts.reset_user_password(fetched_user, %{"password" => "newsecret1"})
      assert Accounts.get_user_by_email_and_password(user.email, "newsecret1").id == updated.id
      refute Accounts.get_user_by_reset_password_token(token)
    end

    test "revokes every existing session (refresh token) on success" do
      user = register_user()
      {:ok, _access_token, refresh_token_a} = Accounts.create_session(user, false)
      {:ok, _access_token, refresh_token_b} = Accounts.create_session(user, true)

      {:ok, _updated} = Accounts.reset_user_password(user, %{"password" => "newsecret1"})

      assert :error = Accounts.refresh_session(refresh_token_a)
      assert :error = Accounts.refresh_session(refresh_token_b)
    end

    test "rejects an unknown token" do
      refute Accounts.get_user_by_reset_password_token("not-a-real-token")
    end
  end

  describe "sessions" do
    test "create_session/2 issues an access token and a refresh token" do
      user = register_user()
      assert {:ok, access_token, refresh_token} = Accounts.create_session(user, false)
      assert is_binary(access_token)
      assert is_binary(refresh_token)
    end

    test "refresh_session/1 rotates a valid refresh token" do
      user = register_user()
      {:ok, _access_token, refresh_token} = Accounts.create_session(user, false)

      assert {:ok, new_access_token, new_refresh_token, false} =
               Accounts.refresh_session(refresh_token)

      assert new_refresh_token != refresh_token
      assert {:ok, claims} = Api.Accounts.Guardian.decode_and_verify(new_access_token)
      assert claims["sub"] == to_string(user.id)

      # the old refresh token was consumed and can't be reused
      assert :error = Accounts.refresh_session(refresh_token)
    end

    test "refresh_session/1 carries the original remember_me flag forward" do
      user = register_user()
      {:ok, _access_token, refresh_token} = Accounts.create_session(user, true)

      assert {:ok, _access_token, _new_refresh_token, true} =
               Accounts.refresh_session(refresh_token)
    end

    test "refresh_session/1 returns :error for an unknown token" do
      assert :error = Accounts.refresh_session("bogus")
    end

    test "revoke_refresh_token/1 invalidates the token" do
      user = register_user()
      {:ok, _access_token, refresh_token} = Accounts.create_session(user, false)

      assert :ok = Accounts.revoke_refresh_token(refresh_token)
      assert :error = Accounts.refresh_session(refresh_token)
    end
  end

  defp token_from_url(url), do: url |> String.split("/") |> List.last()
end
