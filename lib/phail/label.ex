defmodule Phail.Label do
  use Ecto.Schema
  alias Phail.Repo
  alias __MODULE__

  schema "labels" do
    field :name, :string

    many_to_many(
      :messages,
      Phail.Message,
      join_through: "message_label"
    )

    def all() do
      Label |> Repo.all()
    end
  end
end
