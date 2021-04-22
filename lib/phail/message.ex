defmodule Phail.Message do
  alias Bamboo.Email
  import Ecto.Query
  import EctoEnum
  alias Ecto.Changeset
  use Ecto.Schema
  alias Phail.Message
  alias Phail.Repo
  alias Phail.Conversation
  alias Phail.MessageAddress
  alias Phail.MessageReference

  defenum(MessageStatus, :message_status, [:draft, :outbox, :sent])

  schema "messages" do
    field(:subject, :string)
    field(:body, :string)
    field(:date, :utc_datetime)
    field(:status, MessageStatus)
    field(:message_id, :string)
    field(:in_reply_to, :string)
    belongs_to(:conversation, Conversation)

    belongs_to(:user, Phail.Accounts.User)
    has_many(:message_addresses, MessageAddress)
    has_many(:message_references, MessageReference)
  end

  def create(conversation, options \\ []) do
    from = Keyword.get(options, :from, [])
    to = Keyword.get(options, :to, [])
    subject = Keyword.get(options, :subject, "")
    body = Keyword.get(options, :body, "")
    cc = Keyword.get(options, :cc, [])
    status = Keyword.get(options, :status)
    references = Keyword.get(options, :references, [])
    in_reply_to = Keyword.get(options, :in_reply_to)

    conversation = conversation |> Repo.preload(:user)

    message =
      %Message{
        user: conversation.user,
        subject: subject,
        body: body,
        status: status,
        in_reply_to: in_reply_to,
        message_addresses: [],
        conversation: conversation,
        message_id: new_message_id()
      }
      |> Repo.insert!()

    for address <- from do
      add_address(message, :from, address)
    end

    for address <- to do
      add_address(message, :to, address)
    end

    for address <- cc do
      add_address(message, :cc, address)
    end

    for reference <- references do
      add_reference(message, reference)
    end

    get(message.user, message.id)
  end

  def add_address(message, address_type, %{address: address, name: name}) do
    add_address(message, address_type, address, name)
  end

  def add_address(message, address_type, address, name) do
    message
    |> Ecto.build_assoc(:message_addresses, %{
      user: message.user,
      name: name,
      address: address,
      type: Atom.to_string(address_type)
    })
    |> Repo.insert!()

    get(message.user, message.id)
  end

  def remove_address(message, address_id) do
    Phail.MessageAddress.get(message, address_id) |> Repo.delete!()
    get(message.user, message.id)
  end

  def add_reference(message, reference) do
    message
    |> Ecto.build_assoc(:message_references, %{reference: reference})
    |> Repo.insert!()
  end

  def references(message = %Message{}) do
    message = message |> Repo.preload(:message_references)

    for reference <- message.message_references do
      reference.reference
    end
  end

  def delete(message) do
    message
    |> Repo.delete!()
  end

  def update_draft(message, mail_data \\ %{}) do
    message =
      message
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

  def get(user, id) do
    Message
    |> where([m], m.user_id == ^user.id)
    |> Repo.get!(id)
    |> Repo.preload([
      :user,
      :message_addresses,
      :conversation
    ])
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

    [from_address] = Message.from_addresses(message)

    email =
      Email.new_email(
        from: Phail.MailAccount.get_by_email(from_address.address),
        to: Message.to_addresses(message),
        cc: Message.cc_addresses(message),
        subject: message.subject,
        html_body: message.body,
        headers: [
          {"Message-Id", message.message_id},
          {"Date", Calendar.DateTime.Format.rfc2822(local_datetime)},
          {"In-Reply-To", message.in_reply_to},
          {"References", Enum.join(references(message), " ")}
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

  def from_addresses(message) do
    for m = %MessageAddress{type: :from} <- message.message_addresses, do: m
  end

  def to_addresses(message) do
    for m = %MessageAddress{type: :to} <- message.message_addresses, do: m
  end

  def cc_addresses(message) do
    for m = %MessageAddress{type: :cc} <- message.message_addresses, do: m
  end
end
