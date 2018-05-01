defmodule Rumbl.TestHelpers do
  alias Rumbl.{Auth, Videos}

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
    Videos.insert_video!(user, attrs)
  end
end
