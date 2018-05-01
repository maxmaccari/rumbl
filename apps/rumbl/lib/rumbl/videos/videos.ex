defmodule Rumbl.Videos do
  import Ecto
  import Ecto.Query

  alias Rumbl.Repo
  alias Rumbl.Videos.{Annotation, Category, Video}

  def list_videos(user) do
    Repo.all(user_videos(user))
  end

  def find_video!(id) do
    Repo.get!(Video, id)
  end

  def find_video!(user, id) do
    Repo.get!(user_videos(user), id)
  end

  def find_video_by!(params) do
    Repo.get_by!(Video, params)
  end

  def build_video(user, params \\ %{}) do
    user
    |> build_assoc(:videos)
    |> Video.changeset(params)
  end

  def insert_video(user, params \\ %{}) do
    user
    |> build_assoc(:videos)
    |> Video.changeset(params)
    |> Repo.insert
  end

  def insert_video!(user, params \\ %{}) do
    user
    |> Ecto.build_assoc(:videos, params)
    |> Repo.insert!()
  end

  def update_video(video, params \\ %{}) do
    Video.changeset(video, params)
    |> Repo.update
  end

  def delete_video!(user, id) do
    Repo.get!(user_videos(user), id)
    |> Repo.delete!
  end

  def change_video(video \\ %Video{}, params \\ %{}) do
    Video.changeset(video, params)
  end

  def video_count do
    Repo.one(from v in Video, select: count(v.id))
  end

  def list_categories do
    Category
    |> Category.alphabetical
    |> Category.names_and_ids
    |> Repo.all
  end

  def list_video_annotations(video, last_seen_id \\ 0) do
    Repo.all(
      from a in assoc(video, :annotations),
      where: a.id > ^last_seen_id,
      order_by: [asc: a.at, asc: a.id],
      limit: 200,
      preload: [:user]
    )
  end

  def build_annotation(user, video_id, params \\ %{}) do
    user
      |> build_assoc(:annotations, video_id: video_id)
      |> Annotation.changeset(params)
  end

  def insert_annotation(user, video_id, params \\ %{}) do
    build_annotation(user, video_id, params)
    |> Repo.insert
  end

  def preload_user(struct) do
    Repo.preload(struct, :user)
  end

  defp user_videos(user) do
    assoc(user, :videos)
  end
end
