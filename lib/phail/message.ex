defmodule Phail.Message do
  import Ecto.Query

  use Ecto.Schema
  alias Phail.Message
  alias Phail.Repo
  alias Phail.Address
  alias Phail.Conversation

  schema "messages" do
    field(:subject, :string)
    field(:body, :string)
    field(:date, :utc_datetime)
    belongs_to(:conversation, Conversation)

    many_to_many(
      :from_addresses,
      Address,
      join_through: "message_from_address"
    )

    many_to_many(
      :to_addresses,
      Address,
      join_through: "message_to_address"
    )

    many_to_many(
      :cc_addresses,
      Address,
      join_through: "message_cc_address"
    )
  end

  def create(from, to, cc, subject, body) do
    from = Enum.map(from, &Address.get_or_create/1)
    to = Enum.map(to, &Address.get_or_create/1)
    cc = Enum.map(cc, &Address.get_or_create/1)

    %Message{
      subject: subject,
      body: body,
      to_addresses: [],
      from_addresses: [],
      cc_addresses: []
    }
    |> Repo.insert!()
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:from_addresses, from)
    |> Ecto.Changeset.put_assoc(:to_addresses, to)
    |> Ecto.Changeset.put_assoc(:cc_addresses, cc)
    |> Repo.update!()
  end

  defp text_search(search_term) do
    from m in Message,
      where:
        fragment(
          "to_tsvector('english', body || ' ' || subject) @@ to_tsquery('english', ?)",
          ^search_term
        )
  end

  def search(search_term) do
    text_search(search_term)
    |> Repo.all()
    |> Repo.preload([
      :from_addresses,
      :to_addresses,
      :cc_addresses
    ])
  end

  def get(id) do
    Message
    |> Repo.get(id)
    |> Repo.preload([
      :from_addresses,
      :to_addresses,
      :cc_addresses
    ])
  end

  def all() do
    Message |> Repo.all() |> Repo.preload([:from_addresses, :to_addresses, :cc_addresses])
  end
end
