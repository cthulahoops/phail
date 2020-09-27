defmodule MessageTest do
     use ExUnit.Case
     alias Phail.Repo
     alias Phail.{Conversation, Message}
    
     setup do
       :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
     end

    describe "Can set the status on a message" do
      setup do
        conversation = Conversation.create("Test Message")

        message = Message.create(
          conversation,
          subject: "Test Message",
          body: "Some body text for the message"
        )
        %{message: message}
      end

      test "Can set a message status to sent", %{message: message} do
        Message.set_status(message, :sent)
        message = Message.get(message.id)
        assert message.status == :sent
      end
    end
end
