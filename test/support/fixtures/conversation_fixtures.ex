defmodule Phail.ConversationFixtures do
  def valid_conversation(attrs \\ %{}) do
    Enum.into(attrs, %{
      subject: Faker.Pizza.combo(),
      is_draft: false
    })
  end

  def conversation_fixture(user, attrs \\ %{}) do
    conversation = valid_conversation(attrs)
    Phail.Conversation.create(user, conversation.subject, is_draft: conversation.is_draft)
  end
end
