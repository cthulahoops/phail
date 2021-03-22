defmodule Phail.Address do
  use Ecto.Schema
  import Ecto.Query
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

  def get(id) do
    Address |> Repo.get(id)
  end

  def get_or_create(%{address: address, name: name}) do
    case Repo.get_by(Address, address: address, name: name) do
      nil ->
        %Address{address: address, name: name} |> Repo.insert!()

      address ->
        address
    end
  end

  def prefix_search("") do
    []
  end
  def prefix_search(prefix_string) do
    search_pattern = "#{prefix_string}%"

    from(a in Address,
      where:
        ilike(a.name, ^search_pattern) or
          ilike(a.address, ^search_pattern),
      limit: 5
    )
    |> Repo.all()
  end

  defimpl Bamboo.Formatter, for: Phail.Address do
    def format_email_address(address, _opts) do
      {address.name, address.address}
    end
  end
end
