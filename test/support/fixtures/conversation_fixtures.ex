defmodule Phail.ConversationFixtures do
  import Phail.MessageFixtures

  alias Phail.Conversation

  def valid_conversation(attrs \\ %{}) do
    Enum.into(attrs, %{
      subject: Faker.Pizza.combo(),
      is_draft: false
    })
  end

  def conversation_fixture(user, attrs \\ %{}) do
    conversation = valid_conversation(attrs)

    conversation =
      Conversation.create(user, conversation.subject, is_draft: conversation.is_draft)

    for _ <- 1..Map.get(attrs, :num_messages, 1) do
      message_fixture(conversation)
    end

    conversation
    |> Phail.Repo.preload(:labels)
    |> Conversation.add_labels(Map.get(attrs, :labels, []))
    |> Phail.Repo.preload(:messages)
  end
end
