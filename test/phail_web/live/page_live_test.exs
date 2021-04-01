defmodule PhailWeb.PageLiveTest do
  use PhailWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Compose"
    assert render(page_live) =~ "Compose"
  end
end
