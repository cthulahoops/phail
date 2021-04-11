defmodule PhailWeb.ComposeLiveTest do
  use PhailWeb.ConnCase

  import Phail.AccountsFixtures
  import Phail.MessageAddressFixtures
  import Phail.ConversationFixtures
  import Phoenix.LiveViewTest

  setup do
    %{user: user_fixture()}
  end

  test "Add a to address to a message", %{conn: conn, user: user} do
    conn = conn |> log_in_user(user)

    {:ok, view, _disconnected_html} = live(conn, "/compose")

    view
    |> render_hook("add_address", Enum.into(%{"input_id" => "to_input"}, valid_message_address()))
  end

  describe "Can't edit or reply to another users message" do
    setup do
      current_user = user_fixture()
      conversation_owner = user_fixture()
      conversation = conversation_fixture(conversation_owner)
      message_id = hd(conversation.messages).id

      %{
        current_user: current_user, 
        conversation: conversation,
        message_id: message_id
      }
    end

    test "can't access /compose/<message_id>/ ", %{conn: conn, current_user: current_user, message_id: message_id, conversation: _conversation} do
      conn = conn |> log_in_user(current_user)

      assert_raise Ecto.NoResultsError, fn -> live(conn, "/compose/#{ message_id }") end
    end

    test "can't access /compose/<reply_to>/", %{conn: conn, current_user: current_user, message_id: message_id, conversation: _conversation} do
      conn = conn |> log_in_user(current_user)

      assert_raise Ecto.NoResultsError, fn -> live(conn, "/reply/#{ message_id }") end
    end
  end
end
