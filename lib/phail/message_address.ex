defmodule Phail.MessageAddress do
  use Ecto.Schema
  import Ecto.Query
  import EctoEnum
  alias Phail.Repo
  alias Phail.MessageAddress

  defenum(AddressType, :address_type, [:to, :from, :cc, :bcc])

  schema "message_addresses" do
    field :address, :string
    field :name, :string
    field :order, :integer
    field :type, AddressType

    belongs_to :message, Phail.Message
    belongs_to(:user, Phail.Accounts.User)
  end

  def get(id) do
    MessageAddress |> Repo.get(id)
  end

  def prefix_search("") do
    []
  end

  def prefix_search(prefix_string) do
    search_pattern = "#{prefix_string}%"

    from(a in MessageAddress,
      distinct: [a.name, a.address],
      select: %{id: a.id, name: a.name, address: a.address},
      where:
        ilike(a.name, ^search_pattern) or
          ilike(a.address, ^search_pattern),
      limit: 5
    )
    |> Repo.all()
  end
end
