defmodule Phail.Address do
  use Ecto.Schema
  alias Phail.Repo
  alias Phail.Address

  schema "addresses" do
    field(:address, :string)
    field(:name, :string)

    many_to_many(
      :from_messages,
      Phail.Message,
      join_through: "message_from_address"
    )

    many_to_many(
      :to_messages,
      Phail.Message,
      join_through: "message_to_address"
    )

    many_to_many(
      :cc_messages,
      Phail.Message,
      join_through: "message_cc_address"
    )
  end

  def display(%Address{address: address, name: ""}), do: address
  def display(%Address{address: address, name: name}), do: name <> " <" <> address <> ">"

  def display_name(%Address{address: address, name: ""}), do: address
  def display_name(%Address{name: name}), do: name

  def display_short(%Address{address: address, name: ""}), do: address
  def display_short(%Address{name: name}), do: hd(String.split(name, " "))

  def get_or_create(%{address: address, name: name}) do
    case Repo.get_by(Address, address: address, name: name) do
      nil ->
        %Address{address: address, name: name} |> Repo.insert!()

      address ->
        address
    end
  end
end
