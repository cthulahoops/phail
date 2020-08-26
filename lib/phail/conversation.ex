defmodule Phail.Conversation do
  import Ecto.Query
  import Phail.TextSearch
  use Ecto.Schema
  alias Phail.{Conversation, Message, Label, Address}
  alias Phail.Repo
  alias Phail.Query

  schema "conversations" do
    field :subject, :string
    field :date, :utc_datetime, virtual: true
    field :labels, :any, virtual: true

    has_many(:messages, Message)
    many_to_many(:from_addresses, Address, join_through: "conversation_from_address")
  end

  def create(subject) do
    %Conversation{
      subject: subject
    }
    |> Repo.insert!()
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

  def select_by_label(label) do
    select_conversations()
    |> filter_labels([label])
    |> Repo.all()
  end

  def select_drafts() do
    select_conversations()
    |> filter_drafts
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

  defp filter_drafts(conversations) do
    conversations
    |> where([_c, m, _l], m.is_draft)
  end

  def add_label(conversation, label_name) do
    label = Label.get_or_create(label_name)
    Enum.each(conversation.messages, fn message -> Message.add_label(message, label) end)
  end

  def remove_label(conversation_id, label_name) do
    from(j in "message_labels",
      join: m in Message,
      on: m.id == j.message_id,
      join: l in Label,
      on: l.id == j.label_id,
      where: m.conversation_id == ^conversation_id,
      where: l.name == ^label_name
    )
    |> Repo.delete_all()
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
