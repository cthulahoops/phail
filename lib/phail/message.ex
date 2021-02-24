defmodule Phail.Message do
  alias Bamboo.Email
  import Ecto.Query
  import EctoEnum
  alias Ecto.Changeset
  use Ecto.Schema
  alias Phail.Message
  alias Phail.Repo
  alias Phail.Address
  alias Phail.Conversation

  defenum(MessageStatus, :message_status, [:draft, :outbox, :sent])

  schema "messages" do
    field(:subject, :string)
    field(:body, :string)
    field(:date, :utc_datetime)
    field(:status, MessageStatus)
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
    status = Keyword.get(options, :status)

    %Message{
      subject: subject,
      body: body,
      status: status,
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
    message = message
    |> Changeset.change()
    |> Changeset.cast(mail_data, [:subject, :body])
    |> Repo.update!()

    if message.conversation.is_draft do
      message.conversation
      |> Changeset.change()
      |> Changeset.cast(mail_data, [:subject])
      |> Repo.update!()
    end

    message
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

  def set_status(message, status) do
    message
    |> Changeset.cast(%{"status" => status}, [:status])
    |> Repo.update!()
  end

  def send(message) do
    utc_datetime = DateTime.utc_now()

    message
    |> Changeset.cast(%{"date" => utc_datetime}, [:date])
    |> Repo.update!()

    local_datetime = Calendar.DateTime.shift_zone!(utc_datetime, "Europe/London")

    email =
      Email.new_email(
        from: Application.fetch_env!(:phail, :email_sender),
        to: message.to_addresses,
        subject: message.subject,
        html_body: message.body,
        headers: [
          {"Message-Id", message.message_id},
          {"Date", Calendar.DateTime.Format.rfc2822(local_datetime)}
        ]
      )

    message.conversation
    |> Changeset.cast(%{"is_draft" => false}, [:is_draft])
    |> Repo.update!()

    set_status(message, :outbox)

    Phail.Mailer.deliver_now(email)
    set_status(message, :sent)
  end

  defp new_message_id do
    "<" <> UUID.uuid4() <> "@" <> Application.fetch_env!(:phail, :domain) <> ">"
  end
end
