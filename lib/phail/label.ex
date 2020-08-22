defmodule Phail.Label do
  use Ecto.Schema

  schema "labels" do
    field :name, :string

    many_to_many(
      :messages,
      Phail.Message,
      join_through: "message_label"
    )
  end
end
