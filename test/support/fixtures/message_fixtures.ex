defmodule Phail.MessageFixtures do
  import Phail.MessageAddressFixtures

  def valid_message(attrs \\ %{}) do
    Enum.into(attrs, %{
      subject: Faker.Pizza.combo(),
      body: Faker.Lorem.Shakespeare.romeo_and_juliet()
    })
  end

  def message_fixture(conversation, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        subject: conversation.subject,
        from: [valid_message_address()],
        to: [valid_message_address()]
      })

    Phail.Message.create(conversation, Enum.to_list(valid_message(attrs)))
  end
end
