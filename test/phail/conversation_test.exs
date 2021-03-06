defmodule ConversationTest do
  use ExUnit.Case
  alias Phail.Repo
  import Phail.AccountsFixtures
  alias Phail.{Conversation}

  import Phail.{MessageFixtures, ConversationFixtures}

  defp conversation_ids(conversation_list) do
    for c <- conversation_list, do: c.id
  end

  defp label_names(labels) do
    for l <- labels, do: l.name
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "Fetch conversations by status" do
    setup do
      user = user_fixture()

      sent_conversation = conversation_fixture(user, %{subject: "Sent", num_messages: 0})
      message_fixture(sent_conversation, %{status: :sent})

      conversation_fixture(user, %{subject: "Received"})

      %{user: user, sent_conversation: sent_conversation}
    end

    test "Search for sent messages", %{user: user, sent_conversation: sent_conversation} do
      conversations = Conversation.search(user, "is:sent")

      assert [sent_conversation.id] == conversation_ids(conversations)
    end
  end

  describe "Search only returns my own messages" do
    setup do
      me = user_fixture()
      you = user_fixture()
      conversation = conversation_fixture(you, %{subject: "Private", num_messages: 1})

      %{me: me, you: you, conversation: conversation}
    end

    test "I can't see your message", %{me: me} do
      assert [] == Conversation.search(me, "Private")
    end

    test "You can see your own message", %{you: you, conversation: conversation} do
      assert [conversation.id] == conversation_ids(Conversation.search(you, "Private"))
    end
  end

  test "Adding and removing labels works" do
    current_user = user_fixture()

    conversation = conversation_fixture(current_user, %{labels: ["first label", "second label"]})

    conversation = Conversation.add_labels(conversation, ["third label", "fourth label"])

    assert Enum.sort(label_names(conversation.labels)) ==
             Enum.sort(["first label", "second label", "third label", "fourth label"])

    conversation = Conversation.remove_label(conversation, "third label")

    assert Enum.sort(label_names(conversation.labels)) ==
             Enum.sort(["first label", "second label", "fourth label"])
  end
end
