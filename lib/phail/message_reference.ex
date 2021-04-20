defmodule Phail.MessageReference do
  use Ecto.Schema

  @primary_key false
  schema "message_references" do
    field :reference, :string
    belongs_to :message, Phail.Message
  end
end
