defmodule RumblWeb.Auth do
  import Plug.Conn

  def init(_opts) do
  end

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)
    cond do
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)
      user = user_id && Rumbl.Auth.find_user(user_id) ->
        put_current_user(conn, user)
      true ->
        assign(conn, :current_user, nil)
    end
  end

  def login(conn, user) do
    conn
    |> put_current_user(user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end

  defp put_current_user(conn, user) do
    token = Phoenix.Token.sign(conn, "user socket", user.id)

    conn
    |> assign(:current_user, user)
    |> assign(:user_token, token)
  end

  def login_by_username_and_pass(conn, username, given_pass) do
    case Rumbl.Auth.login_by_username_and_pass(username, given_pass) do
      {:ok, user} -> {:ok, login(conn, user)}
      {:error, reason} -> {:error, reason, conn}
    end
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end

  import Phoenix.Controller
  alias RumblWeb.Router.Helpers

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Helpers.page_path(conn, :index))
      |> halt()
    end
  end
end
