defmodule PhailWeb.PageLiveTest do
  use PhailWeb.ConnCase

  import Phail.AccountsFixtures
  import Phoenix.LiveViewTest

  setup do
    %{user: user_fixture()}
  end

  test "can't load page if not logged in", %{conn: conn} do
    {:error, {:redirect, %{to: "/users/log_in"}}} = live(conn, "/")
  end

  test "disconnected and connected render", %{conn: conn, user: user} do
    conn = conn |> log_in_user(user)

    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Compose"
    assert render(page_live) =~ "Compose"
  end
end
