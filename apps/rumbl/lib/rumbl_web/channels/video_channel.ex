defmodule RumblWeb.VideoChannel do
  use RumblWeb, :channel

  alias RumblWeb.AnnotationView
  alias RumblWeb.Presence

  alias Rumbl.Auth

  def join("videos:" <> video_id, params, socket) do
    send self(), :after_join

    last_seen_id = params["last_seen_id"] || 0
    video_id = String.to_integer(video_id)
    video = Repo.get!(Rumbl.Video, video_id)

    annotations = Repo.all(
      from a in assoc(video, :annotations),
      where: a.id > ^last_seen_id,
      order_by: [asc: a.at, asc: a.id],
      limit: 200,
      preload: [:user]
    )

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
    changeset =
      user
      |> build_assoc(:annotations, video_id: socket.assigns.video_id)
      |> Rumbl.Annotation.changeset(params)

    case Repo.insert(changeset) do
      {:ok, annotation} ->
        broadcast_annotation(socket, annotation)
        Task.start_link(fn -> compute_additional_info(annotation, socket) end)
        {:reply, :ok, socket}
      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  defp broadcast_annotation(socket, annotation) do
    annotation = Repo.preload(annotation, :user)
    rendered_ann = Phoenix.View.render(AnnotationView, "annotation.json", %{
      annotation: annotation
    })
    broadcast! socket, "new_annotation", rendered_ann
  end

  defp compute_additional_info(annotation, socket)  do
    for result <- InfoSys.compute(annotation.body, limit: 1,
                                                         timeout: 10_000) do
      attrs = %{url: result.url, body: result.text, at: annotation.at}
      info_changeset =
        Auth.find_user_by_username!(result.backend)
        |> build_assoc(:annotations, video_id: annotation.video_id)
        |> Rumbl.Annotation.changeset(attrs)

      case Repo.insert(info_changeset) do
        {:ok, info_ann} -> broadcast_annotation(socket, info_ann)
        {:error, _changeset} -> :ignore
      end
    end
  end
end
