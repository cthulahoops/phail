defmodule ConversationTest do
  use ExUnit.Case
  alias Phail.Repo
  import Phail.AccountsFixtures
  alias Phail.{Conversation, Message}

  defp conversation_ids(conversation_list) do
    for c <- conversation_list, do: c.id
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "Fetch conversations by status" do
    setup do
      user = user_fixture()
      sent_conversation = Conversation.create(user, "Test Conversation")

      Message.create(
        user,
        sent_conversation,
        subject: "Test Message",
        body: "Some body text for the message",
        status: :sent
      )

      received_conversation = Conversation.create(user, "Not a sent conversation")

      Message.create(
        user,
        received_conversation,
        subject: "Received!",
        body: "I received this"
      )

      %{sent_conversation: sent_conversation}
    end

    test "Search for sent messages", %{sent_conversation: sent_conversation} do
      conversations = Conversation.search("is:sent")

      assert [sent_conversation.id] == conversation_ids(conversations)
    end
  end
end
