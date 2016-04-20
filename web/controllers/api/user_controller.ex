defmodule ChatSecured.Api.UserController do
  use ChatSecured.Web, :controller
  plug :verify_token_and_set_user when action in [:edit, :update, :delete]


  alias ChatSecured.User

  def index(conn, _params) do
    users = Repo.all(User)
    render conn, "index.html", users: users
  end

  #Through pattern matching we will fetch the ID param
  #In this case on ID "1" it will be ->  %{"id" => id} = %{"id" =>  "1"} which will make id=1
  def show(conn, %{"id" => id}) do
    user = Repo.get(User, id)
    render conn, "show.html", user: user
  end

  #%{"user" => %{"email" => "Mike@mike.com", "password" => "[FILTERED]", "password_confirmation" => "[FILTERED]"}}

  #This is how the parameters might look like
  #"user" => %{"name" => "Johnny", "password" => "[FILTERED]", "username" => "JohnnyCage"}}
  def create(conn, %{"user" => user_params}) do
    changeset = User.registration_changeset(%User{}, user_params)
    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> render("user.json", %{token: Phoenix.Token.sign(conn, "user", user.id), user: user})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChatSecured.ChangesetView, "error.json", changeset: changeset)
    end
  end

  #If token is older than 14 days then verification would fail with reason-expired.
  @max_age 2 * 7 * 24 * 60 *60 # 14 days

  def edit(conn, %{"token" => token}) do
    user = conn.assigns[:current_user]

    conn
    |> put_status(:ok)
    |> render("edit.json", %{user: user})
  end

  def update(conn, %{"token" => token, "user" => user_params}) do
    user = conn.assigns[:current_user]
    changeset = User.changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_status(:ok)
        |> text("Account has been updated successfully")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChatSecured.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"token" => token}) do
    user = conn.assigns[:current_user]
    #bang will raise an error incase of a problem
    Repo.delete!(user)
    conn
    |> put_status(:ok)
    |> text("You have successfully deleted your account.")
  end

  def verify_token(conn, %{"token" => token}) do
    #Returns status :ok and the users ID on successful token verification
    case Phoenix.Token.verify(conn, "user", token, max_age: @max_age) do
      {:ok, user_id} ->
        #Checks if user exists after token is verified successfully
        cond do
          user = Repo.get(User, user_id) ->
            conn
            |> put_status(:ok)
            |> render("user.json", %{token: token, user: user})
          #If user not found then the condition will default to this
          true ->
            conn
            |> put_status(:not_found)
            |> text("User not found")
        end
      {:error, _reason} ->
        conn
        |> put_status(:not_acceptable)
        |> text("token failed verification")
    end
  end

  defp verify(conn, token) do
    #Returns status :ok and the users ID on successful token verification
    case Phoenix.Token.verify(conn, "user", token, max_age: @max_age) do
      {:ok, user_id} ->
        cond do
          user = Repo.get(User, user_id) ->
            {conn, user}
          true ->
            conn
            |> put_status(:not_found)
            |> text("User not found")
        end
      {:error, _reason} ->
        conn
        |> put_status(:not_acceptable)
        |> text("token failed verification")
    end
  end
end
