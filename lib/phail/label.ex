defmodule Phail.Label do
  import Ecto.Query
  use Ecto.Schema
  alias Phail.Repo
  alias __MODULE__

  schema "labels" do
    field :name, :string

    many_to_many(
      :messages,
      Phail.Message,
      join_through: "message_labels"
    )
  end

  def all() do
    from(l in Label,
      order_by: l.name
    )
    |> Repo.all()
  end

  def get_or_create(label_name) do
    {:ok, label} = %Label{name: label_name} |> Repo.insert(on_conflict: :nothing)

    if is_nil(label.id) do
      Repo.get_by(Label, name: label_name)
    else
      label
    end
  end
end
