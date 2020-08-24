defmodule Phail.Conversation do
  import Ecto.Query
  import Phail.TextSearch
  use Ecto.Schema
  alias Phail.Address
  alias Phail.Message
  alias Phail.Conversation
  alias Phail.Repo
  alias Phail.Query

  schema "conversations" do
    field :subject, :string
    field :date, :utc_datetime, virtual: true
    field :labels, :any, virtual: true

    has_many(:messages, Message)
    many_to_many(:from_addresses, Address, join_through: "conversation_from_address")
  end

  def search("") do
    search("label:inbox")
  end

  def search(search_term) do
    query = Query.parse_query(search_term)

    select_conversations()
    |> text_search(query.text)
    |> filter_labels(query.labels)
    |> Repo.all()
  end

  defp select_conversations() do
    from c in Conversation,
      join: m in Message,
      on: c.id == m.conversation_id,
      join: l in assoc(m, :labels),
      select: %{c | date: max(m.date), labels: fragment("array_agg(distinct ?)", l.name)},
      group_by: c.id,
      order_by: [desc: max(m.date)],
      limit: 20,
      preload: [:from_addresses]
  end

  defp text_search(conversations, "") do
    conversations
  end

  defp text_search(conversations, search_term) do
    conversations |> where([_c, m], fulltext(space_join(m.body, m.subject), ^search_term))
  end

  defp filter_labels(conversations, labels) do
    conversations
    |> having([_c, _m, l], fragment("? <@ array_agg(?)", ^labels, l.name))
  end

  def get(id) do
    Conversation
    |> Repo.get(id)
    |> Repo.preload(
      messages:
        from(m in Message,
          order_by: m.date,
          preload: [
            :from_addresses,
            :to_addresses,
            :cc_addresses,
            :labels
          ]
        )
    )
  end
end
