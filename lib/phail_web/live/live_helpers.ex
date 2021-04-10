defmodule PhailWeb.LiveHelpers do
  import Phoenix.LiveView
  alias Phail.Accounts
  alias Phail.Accounts.User
  alias PhailWeb.Router.Helpers, as: Routes

  def assign_defaults(socket, session) do
    socket =
      assign_new(socket, :current_user, fn ->
        find_current_user(session)
      end)

    case socket.assigns.current_user do
      %User{} ->
        socket

      _other ->
        socket
        |> put_flash(:error, "You must log in to access this page.")
        |> redirect(to: Routes.user_session_path(socket, :new))
    end
  end

  defp find_current_user(session) do
    user_token = session["user_token"]

    if not is_nil(user_token) do
      %User{} = user = Accounts.get_user_by_session_token(user_token)
      user
    end
  end
end
