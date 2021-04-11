defmodule Phail.MessageFixtures do
  def valid_message(attrs \\ %{}) do
    Enum.into(attrs, %{
      subject: Faker.Pizza.combo(),
      body: Faker.Lorem.Shakespeare.romeo_and_juliet()
    })
  end

  def message_fixture(conversation, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{subject: conversation.subject})
    Phail.Message.create(conversation, Enum.to_list(valid_message(attrs)))
  end
end
