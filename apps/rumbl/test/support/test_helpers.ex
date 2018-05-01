defmodule Rumbl.TestHelpers do
  alias Rumbl.{Repo, Auth}

  def insert_user(attrs \\ []) do
    Keyword.merge([
      name: "Some User",
      username: "user#{Base.encode16(:crypto.strong_rand_bytes(8))}",
      password: "supersecret"
    ], attrs)
    |> Enum.into(%{})
    |> Auth.register_user!
  end

  def insert_video(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:videos, attrs)
    |> Repo.insert!()
  end
end
