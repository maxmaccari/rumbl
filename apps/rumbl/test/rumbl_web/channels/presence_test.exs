defmodule RumblWeb.Channels.PresenceTest do
  use RumblWeb.ChannelCase
  import Rumbl.TestHelpers

  setup do
    user = insert_user(name: "Rebecca", username: "rebecca")
    video = insert_video(user, title: "Testing")
    token = Phoenix.Token.sign(@endpoint, "user socket", user.id)
    {:ok, socket} = connect(RumblWeb.UserSocket, %{"token" => token})

    {:ok, socket: socket, user: user, video: video}
  end

  test "join add username to presence", %{socket: socket, video: vid} do
    {:ok, _, _} = subscribe_and_join(socket, "videos:#{vid.id}", %{})


    assert_push "presence_state", %{"rebecca" => %{metas: [%{phx_ref: ref}]}}
    assert_push "presence_diff", %{joins: %{"rebecca" => %{metas: [%{phx_ref: ^ref}]}}, leaves: %{}}
    assert_broadcast "presence_diff", %{joins: %{"rebecca" => %{metas: [%{phx_ref: ^ref}]}}, leaves: %{}}
  end

  test "leave remove username from presence", %{socket: socket, video: vid} do
    {:ok, _, socket} = subscribe_and_join(socket, "videos:#{vid.id}", %{})
    leave(socket)

    assert_broadcast "presence_diff", %{joins: %{}, leaves: %{"rebecca" => %{metas: [%{phx_ref: _}]}}}
  end
end
