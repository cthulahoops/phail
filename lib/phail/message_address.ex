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

  def get(user = %Phail.Accounts.User{}, id) do
    MessageAddress |> where([ma], ma.user_id == ^user.id) |> Repo.get!(id)
  end

  def get(message = %Phail.Message{}, id) do
    MessageAddress |> where([ma], ma.message_id == ^message.id) |> Repo.get!(id)
  end

  def prefix_search(_user, "") do
    []
  end

  def prefix_search(user, prefix_string) do
    search_pattern = "#{prefix_string}%"

    from(a in MessageAddress,
      distinct: [a.name, a.address],
      select: %{id: a.id, name: a.name, address: a.address},
      where: a.user_id == ^user.id,
      where:
        ilike(a.name, ^search_pattern) or
          ilike(a.address, ^search_pattern),
      limit: 5
    )
    |> Repo.all()
  end
end
