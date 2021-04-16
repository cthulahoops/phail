defmodule PhailWeb.PageLiveTest do
  use PhailWeb.ConnCase

  import Phail.AccountsFixtures
  import Phail.ConversationFixtures
  import Phoenix.LiveViewTest

  setup do
    %{current_user: user_fixture()}
  end

  test "can't load page if not logged in", %{conn: conn} do
    {:error, {:redirect, %{to: "/users/log_in"}}} = live(conn, "/")
  end

  test "disconnected and connected render", %{conn: conn, current_user: current_user} do
    conn = conn |> log_in_user(current_user)
    {:ok, page_live, disconnected_html} = live(conn, "/")

    assert disconnected_html =~ "Compose"
    assert render(page_live) =~ "Compose"
  end

  test "Can't see another user's labels", %{conn: conn, current_user: current_user} do
    other_user = user_fixture()
    conversation_fixture(other_user, %{labels: ["Private Label"]})

    conn = conn |> log_in_user(current_user)
    {:ok, page_live, disconnected_html} = live(conn, "/")

    refute disconnected_html =~ "Private Label"
    refute render(page_live) =~ "Private Label"
  end

  test "Can change the labels on a message.", %{conn: conn, current_user: current_user} do
    conversation = conversation_fixture(current_user, %{labels: ["Existing", "Other"]})

    conn = conn |> log_in_user(current_user)
    {:ok, view, _disconnected_html} = live(conn, "/label/Existing")

    view |> render_click("move", %{"id" => conversation.id, "target" => "New"})

    assert Enum.sort(["New", "Other"]) ==
             Enum.sort(
               for l <- Phail.Conversation.get(current_user, conversation.id).labels, do: l.name
             )
  end
end
