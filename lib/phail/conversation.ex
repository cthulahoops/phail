defmodule Phail.Conversation do
  import Ecto.Query
  import Phail.TextSearch
  use Ecto.Schema
  alias Phail.Address
  alias Phail.Message
  alias Phail.Conversation
  alias Phail.Repo

  schema "conversations" do
    field :subject, :string
    field :date, :utc_datetime, virtual: true

    has_many(:messages, Message)
    many_to_many(:from_addresses, Address, join_through: "conversation_from_address")
  end

  def search("") do
    select_conversations() |> Repo.all()
  end

  def search(search_term) do
    text_search(search_term)
    |> Repo.all()
  end

  defp select_conversations() do
    from c in Conversation,
      join: m in Message,
      on: c.id == m.conversation_id,
      select: %{c | date: max(m.date)},
      group_by: c.id,
      order_by: [desc: max(m.date)],
      limit: 20,
      preload: [:from_addresses]
  end

  defp text_search(search_term) do
    select_conversations()
    |> where([_c, m], fulltext(space_join(m.body, m.subject), ^search_term))
  end

  def get(id) do
    Conversation
    |> Repo.get(id)
    |> Repo.preload(
      messages:
        from(m in Message,
          order_by: m.date,
          preload: [:from_addresses, :to_addresses, :cc_addresses]
        )
    )
  end
end
