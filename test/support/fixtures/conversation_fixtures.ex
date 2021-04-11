defmodule Phail.ConversationFixtures do
  import Phail.MessageFixtures

  def valid_conversation(attrs \\ %{}) do
    Enum.into(attrs, %{
      subject: Faker.Pizza.combo(),
      is_draft: false
    })
  end

  def conversation_fixture(user, attrs \\ %{}) do
    conversation = valid_conversation(attrs)

    conversation = Phail.Conversation.create(user, conversation.subject, is_draft: conversation.is_draft)
    for _ <- 1..Map.get(attrs, :num_messages, 1) do
      message_fixture(conversation)
    end
    conversation
  end
end
