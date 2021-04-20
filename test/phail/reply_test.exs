defmodule ReplyTest do
  use ExUnit.Case
  alias Phail.Repo
  import Phail.AccountsFixtures

  alias Phail.{Message, Reply}

  import Phail.{MessageFixtures, ConversationFixtures}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "Create a reply to a simple message." do
    current_user = user_fixture()
    message = message_fixture(conversation_fixture(current_user))
    reply = Reply.create("one", message)
    assert reply.status == :draft

    assert Phail.DataCase.address_list(Message.to_addresses(reply)) ==
             Phail.DataCase.address_list(Message.from_addresses(message))
  end

  test "Create a reply in a conversation." do
    current_user = user_fixture()
    conversation = conversation_fixture(current_user)
    message = message_fixture(conversation)
    message_2 = message_fixture(conversation, %{references: [message.message_id]})

    reply = Reply.create("one", message_2)

    assert reply.status == :draft
    assert reply.in_reply_to == message_2.message_id
  end
end
