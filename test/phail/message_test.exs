defmodule MessageTest do
  use ExUnit.Case
  use Bamboo.Test

  alias Phail.Repo
  alias Phail.{Conversation, Message}

  import Phail.AccountsFixtures
  import Phail.MessageAddressFixtures
  import Phail.MessageFixtures

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "Can set the status on a message" do
    setup do
      user = user_fixture()
      conversation = Conversation.create(user, "Test Message")
      message = message_fixture(conversation)

      %{message: message}
    end

    test "Can set a message status to sent", %{message: message} do
      Message.set_status(message, :sent)
      message = Message.get(message.user, message.id)
      assert message.status == :sent
    end
  end

  describe "Message sending" do
    setup do
      user = user_fixture()
      conversation = Conversation.create(user, "Test Message")
      message = message_fixture(conversation, %{to: [valid_message_address()]})
      %{message: message}
    end

    test "Sending sets message date.", %{message: message} do
      assert message.date == nil
      Message.send(message)

      message = Message.get(message.user, message.id)
      assert message.date != nil
    end
  end

  describe "Message updates" do
    setup do
      user = user_fixture()
      message = message_fixture(Conversation.create(user, "Test Message"), %{to: [], from: []})

      %{user: user, message_id: message.id}
    end

    test "Add and remove an address", %{user: user, message_id: message_id} do
      valid_address = valid_message_address()

      message =
        Message.get(user, message_id)
        |> Message.add_address(:to, valid_address)
        |> Repo.preload(:message_addresses)

      [address] = message.message_addresses

      assert address.address == valid_address.address
      assert address.name == valid_address.name
      assert address.type == :to

      message = Message.remove_address(message, address.id)

      assert message.message_addresses == []
    end
  end
end
