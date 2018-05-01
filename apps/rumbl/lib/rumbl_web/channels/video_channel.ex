defmodule RumblWeb.VideoChannel do
  use RumblWeb, :channel

  alias RumblWeb.AnnotationView
  alias RumblWeb.Presence

  alias Rumbl.{Auth, Videos}

  def join("videos:" <> video_id, params, socket) do
    send self(), :after_join

    last_seen_id = params["last_seen_id"] || 0
    video_id = String.to_integer(video_id)
    video = Videos.find_video!(video_id)

    annotations = Videos.list_video_annotations(video, last_seen_id)

    resp = %{annotations: Phoenix.View.render_many(annotations, AnnotationView, "annotation.json")}

    {:ok, resp, assign(socket, :video_id, video_id)}
  end

  def handle_info(:after_join, socket) do
    user = Auth.find_user(socket.assigns.user_id)
    Presence.track(socket, user.username, %{})
    push socket, "presence_state", Presence.list(socket)

    {:noreply, socket}
  end

  def handle_in(event, params, socket) do
    user = Auth.find_user(socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  def handle_in("new_annotation", params, user, socket) do
    case Videos.insert_annotation(user, socket.assigns.video_id, params) do
      {:ok, annotation} ->
        broadcast_annotation(socket, annotation)
        Task.start_link(fn -> compute_additional_info(annotation, socket) end)
        {:reply, :ok, socket}
      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  defp broadcast_annotation(socket, annotation) do
    annotation = Videos.preload_user(annotation)
    rendered_ann = Phoenix.View.render(AnnotationView, "annotation.json", %{
      annotation: annotation
    })
    broadcast! socket, "new_annotation", rendered_ann
  end

  defp compute_additional_info(annotation, socket)  do
    for result <- InfoSys.compute(annotation.body, limit: 1,
                                                         timeout: 10_000) do
      attrs = %{url: result.url, body: result.text, at: annotation.at}
      user = Auth.find_user_by_username!(result.backend)

      case Videos.insert_annotation(user, annotation.video_id, attrs) do
        {:ok, info_ann} -> broadcast_annotation(socket, info_ann)
        {:error, _changeset} -> :ignore
      end
    end
  end
end
