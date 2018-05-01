defmodule RumblWeb.UserController do
  use RumblWeb, :controller
  plug :authenticate_user when action in [:index, :show]

  alias Rumbl.Auth

  def index(conn, _params) do
    users = Auth.list_users
    render conn, "index.html", users: users
  end

  def show(conn, %{"id" => id}) do
    user = Auth.find_user(id)
    render conn, "show.html", user: user
  end

  def new(conn, _params) do
    changeset = Auth.change_user
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"user" => user_params}) do
    case Auth.register_user(user_params) do
      {:ok, user} ->
        conn
        |> RumblWeb.Auth.login(user)
        |> put_flash(:info, "#{user.name} created!")
        |> redirect(to: user_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
