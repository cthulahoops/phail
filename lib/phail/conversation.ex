defmodule Phail.Conversation do
  import Ecto.Query
  import Phail.TextSearch
  use Ecto.Schema
  alias Ecto.Changeset
  alias Phail.{Conversation, Message, Label, Address}
  alias Phail.Repo
  alias Phail.Query

  schema "conversations" do
    field :subject, :string
    field :date, :utc_datetime, virtual: true

    has_many(:messages, Message)
    many_to_many(:from_addresses, Address, join_through: "conversation_from_address")

    many_to_many(
      :labels,
      Label,
      join_through: "conversation_labels",
      on_replace: :delete,
      on_delete: :delete_all
    )
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
    query = Query.parse(search_term)

    select_conversations()
    |> text_search(Enum.join(query.text_terms, " & "))
    |> filter_labels(query.labels)
    |> filter_message_statuses(query.statuses)
    |> Repo.all()
  end

  def select_by_label(label) do
    select_conversations()
    |> filter_label(label)
    |> Repo.all()
  end

  def select_drafts() do
    select_conversations()
    |> filter_message_status(:draft)
    |> Repo.all()
  end

  defp select_conversations() do
    from c in Conversation,
      join: m in Message,
      on: c.id == m.conversation_id,
      select: %{
        c
        | date: max(m.date)
      },
      group_by: c.id,
      order_by: [desc: max(m.date)],
      limit: 20,
      preload: [:from_addresses, :labels]
  end

  defp text_search(conversations, "") do
    conversations
  end

  defp text_search(conversations, search_term) do
    conversations |> where([_c, m], fulltext(space_join(m.body, m.subject), ^search_term))
  end

  defp filter_labels(conversation_query, label_names) do
    Enum.reduce(label_names, conversation_query, &filter_label(&2, &1))
  end

  defp filter_label(conversation_query, label_name) do
    conversation_query
    |> where(
      [c, _m],
      c.id in subquery(
        from cl in "conversation_labels",
          select: cl.conversation_id,
          join: l in Label,
          on: l.id == cl.label_id,
          where: l.name == ^label_name
      )
    )
  end

  defp filter_message_statuses(conversation_query, statuses) do
    Enum.reduce(statuses, conversation_query, &filter_message_status(&2, &1))
  end

  defp filter_message_status(conversation_query, status) do
    conversation_query
    |> where([_c, m, _l], m.status == ^status)
  end

  # TODO Write a test to check this works.
  def add_label(conversation, label_name) do
    label = Label.get_or_create(label_name)

    Changeset.change(conversation)
    |> Changeset.put_assoc(:labels, [label | conversation.labels])
    |> Repo.update!()
  end

  def remove_label(conversation_id, label_name) do
    from(cl in "conversation_labels",
      join: l in Label,
      on: l.id == cl.label_id,
      where: cl.conversation_id == ^conversation_id,
      where: l.name == ^label_name
    )
    |> Repo.delete_all()
  end

  def get(id) do
    Conversation
    |> Repo.get(id)
    |> Repo.preload(:labels)
    |> Repo.preload(
      messages:
        from(m in Message,
          order_by: m.date,
          preload: [
            :from_addresses,
            :to_addresses,
            :cc_addresses
          ]
        )
    )
  end
end
