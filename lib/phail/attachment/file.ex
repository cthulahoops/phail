defmodule Phail.Attachment.File do
  use Ecto.Schema
  import Ecto.Changeset
  import EctoEnum

  defenum(Disposition, :disposition, [:inline, :attachment])

  schema "files" do
    field :data, :binary
    field :content_type, :string
    field :disposition, Disposition
    field :filename, :string
    field :user_id, :id
    field :message_id, :id

    timestamps()
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:data, :content_type, :disposition, :filename, :user_id, :message_id])
    |> validate_required([:data, :content_type, :filename, :user_id, :message_id])
  end
end
