defmodule Phail.MessageAddressFixtures do
  def unique_user_email, do: "addr#{System.unique_integer()}@example.com"

  def valid_message_address(attrs \\ %{}) do
    Enum.into(attrs, %{
      address: unique_user_email(),
      name: Faker.Person.name()
    })
  end
end
