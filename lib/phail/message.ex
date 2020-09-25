defmodule Phail.Message do
  import Ecto.Query
  alias Ecto.Changeset
  use Ecto.Schema
  alias Phail.Message
  alias Phail.Repo
  alias Phail.Address
  alias Phail.Conversation

  schema "messages" do
    field(:subject, :string)
    field(:body, :string)
    field(:date, :utc_datetime)
    field(:is_draft, :boolean)
    field(:message_id, :string)
    belongs_to(:conversation, Conversation)

    many_to_many(
      :from_addresses,
      Address,
      join_through: "message_from_address"
    )

    many_to_many(
      :to_addresses,
      Address,
      join_through: "message_to_address",
      on_replace: :delete
    )

    many_to_many(
      :cc_addresses,
      Address,
      join_through: "message_cc_address",
      on_replace: :delete
    )
  end

  def create(conversation, options \\ []) do
    from = Keyword.get(options, :from, [])
    to = Keyword.get(options, :to, [])
    subject = Keyword.get(options, :subject, "")
    body = Keyword.get(options, :body, "")
    cc = Keyword.get(options, :cc, [])
    is_draft = Keyword.get(options, :is_draft, false)

    %Message{
      subject: subject,
      body: body,
      is_draft: is_draft,
      to_addresses: [],
      from_addresses: [],
      cc_addresses: [],
      conversation: conversation,
      message_id: new_message_id()
    }
    |> Repo.insert!()
    |> Changeset.change()
    |> Changeset.put_assoc(:from_addresses, from)
    |> Changeset.put_assoc(:to_addresses, to)
    |> Changeset.put_assoc(:cc_addresses, cc)
    |> Repo.update!()
  end

  def add_to_address(message, to_address) do
    message
    |> Changeset.change()
    |> Changeset.put_assoc(:to_addresses, [to_address | message.to_addresses])
    |> Repo.update!()
  end

  def remove_to_address(message, to_address) do
    message
    |> Changeset.change()
    |> Changeset.put_assoc(:to_addresses, List.delete(message.to_addresses, to_address))
    |> Repo.update!()
  end

  def delete(message) do
    message
    |> Repo.delete!()
  end

  def update_draft(message, mail_data \\ %{}) do
    message
    |> Changeset.change()
    |> Changeset.cast(mail_data, [:subject, :body])
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
      :cc_addresses,
      :conversation
    ])
  end

  def all() do
    Message |> Repo.all() |> Repo.preload([:from_addresses, :to_addresses, :cc_addresses])
  end

  defp new_message_id do
    "<" <> UUID.uuid4() <> "@" <> Application.fetch_env!(:phail, :domain) <> ">"
  end
end
