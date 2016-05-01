defmodule ChatSecured.Api.RoomController do
  use ChatSecured.Web, :controller
  plug :verify_token_and_set_user when action in [:create]

  alias ChatSecured.Room

  plug :scrub_params, "room" when action in [:create, :update]

  def index(conn, _params) do
    rooms = Repo.all(Room)
    render(conn, "index.json", rooms: rooms)
  end

  def create(conn, %{"token" => token, "room" => room_params}) do
    #changeset = Room.changeset(%Room{}, room_params)
    user = conn.assigns[:current_user]
    changeset =
      user
      |> build_assoc(:rooms)
      |> Room.changeset(room_params)

    case Repo.insert(changeset) do
      {:ok, room} ->
        conn
        |> put_status(:created)
        |> render("show.json", room: room)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChatSecured.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    room = Repo.get!(Room, id)
    render(conn, "show.json", room: room)
  end

  def update(conn, %{"id" => id, "room" => room_params}) do
    room = Repo.get!(Room, id)
    changeset = Room.changeset(room, room_params)

    case Repo.update(changeset) do
      {:ok, room} ->
        render(conn, "show.json", room: room)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChatSecured.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    room = Repo.get!(Room, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(room)

    send_resp(conn, :no_content, "")
  end
end
