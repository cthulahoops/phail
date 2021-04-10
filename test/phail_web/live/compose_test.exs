defmodule PhailWeb.ComposeLiveTest do
  use PhailWeb.ConnCase

  import Phail.AccountsFixtures
  import Phoenix.LiveViewTest

  setup do
    %{user: user_fixture()}
  end

  test "Add a to address to a message", %{conn: conn, user: user} do
    conn = conn |> log_in_user(user)

    {:ok, view, _disconnected_html} = live(conn, "/compose")

    view
    |> render_hook("add_address", %{
      "input_id" => "to_input",
      "address" => "test@example.com",
      "name" => "Mr F. Bar"
    })
  end
end
