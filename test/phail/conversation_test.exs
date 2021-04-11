defmodule ConversationTest do
  use ExUnit.Case
  alias Phail.Repo
  import Phail.AccountsFixtures
  alias Phail.{Conversation}

  import Phail.{MessageFixtures, ConversationFixtures}

  defp conversation_ids(conversation_list) do
    for c <- conversation_list, do: c.id
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "Fetch conversations by status" do
    setup do
      user = user_fixture()

      sent_conversation = conversation_fixture(user, %{subject: "Sent"})
      message_fixture(sent_conversation, %{status: :sent})

      received_conversation = conversation_fixture(user, %{subject: "Received"})
      message_fixture(received_conversation)

      %{sent_conversation: sent_conversation}
    end

    test "Search for sent messages", %{sent_conversation: sent_conversation} do
      conversations = Conversation.search("is:sent")

      assert [sent_conversation.id] == conversation_ids(conversations)
    end
  end
end
