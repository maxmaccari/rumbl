defmodule Rumbl.Auth do
  alias Rumbl.Auth.User
  alias Rumbl.Repo

  def list_users do
    Repo.all(User)
  end

  def find_user(id) do
    Repo.get(User, id)
  end

  def find_user_by_username!(username) do
    Repo.get_by!(Rumbl.Auth.User, username: username)
  end

  def register_user(params) do
    User.registration_changeset(%User{}, params)
    |> Repo.insert
  end

  def register_user!(params) do
    User.registration_changeset(%User{}, params)
    |> Repo.insert!
  end

  def change_user(params \\ %{}) do
    User.changeset(%User{}, params)
  end

  def change_user_registration(params \\ %{}) do
    User.registration_changeset(%User{}, params)
  end

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  def login_by_username_and_pass(username, given_pass) do
    user = Repo.get_by(Rumbl.Auth.User, username: username)

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, user}
      user ->
        {:error, :unauthorized}
      true ->
        dummy_checkpw()
        {:error, :not_found}
    end
  end
end
