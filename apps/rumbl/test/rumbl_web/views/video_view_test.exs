defmodule RumblWeb.VideoViewTest do
  use RumblWeb.ConnCase, async: true
  import Phoenix.View

  alias Rumbl.Videos

  test "renders index.html", %{conn: conn} do
    videos = [%Rumbl.Videos.Video{id: "1", title: "dogs"},
              %Rumbl.Videos.Video{id: "2", title: "cats"}]
    content = render_to_string(RumblWeb.VideoView, "index.html",
                               conn: conn, videos: videos)

    assert String.contains?(content, "Listing videos")
    for video <- videos do
      assert String.contains?(content, video.title)
    end
  end

  test "renders new.html", %{conn: conn} do
    changeset = Videos.change_video
    categories = [{"cats", 123}]
    content = render_to_string(RumblWeb.VideoView, "new.html",
      conn: conn, changeset: changeset, categories: categories)

    assert String.contains?(content, "New video")
  end
end
