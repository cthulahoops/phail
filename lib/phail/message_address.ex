defmodule Phail.MessageAddress do
  use Ecto.Schema
  import Ecto.Query
  alias Phail.Repo
  alias Phail.MessageAddress

  schema "message_addresses" do
    field :address, :string
    field :name, :string
    field :order, :integer
    field :type, :string

    belongs_to :message, Phail.Message
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
