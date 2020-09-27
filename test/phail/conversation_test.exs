defmodule ConversationTest do
  use ExUnit.Case
  alias Phail.Repo
  alias Phail.{Conversation, Message}

  defp conversation_ids(conversation_list) do
    for c <- conversation_list, do: c.id
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "Fetch conversations by status" do
    setup do
      conversation = Conversation.create("Test Conversation")

      Message.create(
        conversation,
        subject: "Test Message",
        body: "Some body text for the message",
        status: :sent
      )

      %{conversation: conversation}
    end

    test "Search for sent messages", %{conversation: conversation} do
      conversations = Conversation.search("is:sent")

      assert [conversation.id] == conversation_ids(conversations)
    end
  end
end
