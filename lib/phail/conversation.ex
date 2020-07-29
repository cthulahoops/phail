defmodule Phail.Conversation do
  import Ecto.Query
  import Phail.TextSearch
  use Ecto.Schema
  alias Phail.Message
  alias Phail.Conversation
  alias Phail.Repo

  schema "conversations" do
    field(:subject, :string)

    has_many(:messages, Message)
  end

  def all() do
    Conversation |> Repo.all()
  end

  def search("") do
    Conversation |> Repo.all()
  end

  def search(search_term) do
    text_search(search_term)
    |> Repo.all()
  end

  defp text_search(search_term) do
    from c in Conversation,
      distinct: c.id,
      join: m in Message,
      on: c.id == m.conversation_id,
      where: fulltext(space_join(m.body, m.subject), ^search_term)
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
