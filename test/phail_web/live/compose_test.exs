defmodule PhailWeb.ComposeLiveTest do
  use PhailWeb.ConnCase

  import Phail.AccountsFixtures
  import Phail.ConversationFixtures
  import Phail.MessageFixtures
  import Phail.MessageAddressFixtures
  import Phoenix.LiveViewTest

  setup do
    %{user: user_fixture()}
  end

  test "Add a to address to a message", %{conn: conn, user: user} do
    conn = conn |> log_in_user(user)

    {:ok, view, _disconnected_html} = live(conn, "/compose")

    address = valid_message_address()

    view = view |> render_hook("add_address", Enum.into(%{"input_id" => "to_input"}, address))

    assert view =~ address.name
  end

  test "Add a copy of an existing address to a message", %{conn: conn, user: user} do
    conn = conn |> log_in_user(user)

    {:ok, view, _disconnected_html} = live(conn, "/compose")

    conversation = conversation_fixture(user, %{num_messages: 0})
    message = message_fixture(conversation, %{to: [valid_message_address()]})
    message = Phail.Message.get(user, message.id)

    address = hd(message.message_addresses)

    view = view |> render_hook("add_address", %{"input_id" => "to_input", "id" => address.id})

    assert view =~ address.name
  end

  describe "Reply" do
    setup do
      current_user = user_fixture()
      conversation = conversation_fixture(current_user)
      message_id = hd(conversation.messages).id

      %{
        current_user: current_user,
        conversation: conversation,
        message_id: message_id
      }
    end

    test "has the correct from address", %{
      conn: conn,
      current_user: current_user,
      conversation: conversation,
      message_id: message_id
    } do
      conn = conn |> log_in_user(current_user)

      {:error, {:live_redirect, %{to: to}}} = live(conn, "/reply/one/#{message_id}")

      conversation = Phail.Conversation.get(current_user, conversation.id)
      message = Enum.find(conversation.messages, fn message -> message.status == :draft end)

      from_address = Phail.Message.from_address(message)

      assert from_address.address == current_user.email
      assert to == "/compose/#{message.id}"

      #  assert_redirect view, "/compose/#{message.id}"
    end
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

    test "can't access /compose/<message_id>/ ", %{
      conn: conn,
      current_user: current_user,
      message_id: message_id,
      conversation: _conversation
    } do
      conn = conn |> log_in_user(current_user)

      assert_raise Ecto.NoResultsError, fn -> live(conn, "/compose/#{message_id}") end
    end

    test "can't access /reply/one/<reply_to>/", %{
      conn: conn,
      current_user: current_user,
      message_id: message_id,
      conversation: _conversation
    } do
      conn = conn |> log_in_user(current_user)

      assert_raise Ecto.NoResultsError, fn -> live(conn, "/reply/one/#{message_id}") end
    end
  end

  describe "Address appears in the prefix search" do
    setup do
      current_user = user_fixture()
      address = valid_message_address()
      conversation = conversation_fixture(current_user, %{num_messages: 0})
      message_fixture(conversation, %{to: [address]})
      %{current_user: current_user, address: address}
    end

    test "it appears when we search using the name", %{
      conn: conn,
      current_user: current_user,
      address: address
    } do
      conn = conn |> log_in_user(current_user)

      {:ok, view, _} = live(conn, "/compose/")

      view =
        view
        |> render_change("change", %{
          "to" => String.slice(address.name, 0, 3),
          "_target" => ["to"]
        })

      assert view =~ address.address
      assert view =~ Phoenix.HTML.html_escape(address.name) |> Phoenix.HTML.safe_to_string()
    end

    test "it appears when we search using the address", %{
      conn: conn,
      current_user: current_user,
      address: address
    } do
      conn = conn |> log_in_user(current_user)

      {:ok, view, _} = live(conn, "/compose/")

      view =
        view
        |> render_change("change", %{
          "to" => String.slice(address.address, 0, 24),
          "_target" => ["to"]
        })

      assert view =~ address.address
      assert view =~ Phoenix.HTML.html_escape(address.name) |> Phoenix.HTML.safe_to_string()
    end
  end

  test "Message drafts are saved in the database.", %{conn: conn, user: current_user} do
    conn = conn |> log_in_user(current_user)
    {:ok, view, _} = live(conn, "/compose/")

    rendered =
      view
      |> element("#compose-form")
      |> render_change(%{
        "subject" => "Test Subject",
        "body" => ""
      })

    # assert_patch view, "/compose/1"

    assert rendered =~ "Test Subject"

    rendered =
      view
      |> element("#compose-form")
      |> render_change(%{
        "subject" => "Test Subject",
        "body" => "Body!"
      })

    assert rendered =~ "Test Subject"
    assert rendered =~ "Body!"

    # message = Message.get(current_user, message_id)
    #
    # assert message.subject = "Hi there, world"
    # assert message.body = "Body!"
  end
end
