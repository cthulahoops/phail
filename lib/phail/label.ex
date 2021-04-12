defmodule Phail.Label do
  import Ecto.Query
  use Ecto.Schema
  alias Phail.Repo
  alias __MODULE__

  schema "labels" do
    field :name, :string
    belongs_to(:user, Phail.Accounts.User)

    many_to_many(
      :messages,
      Phail.Message,
      join_through: "message_labels"
    )
  end

  def all(user) do
    from(l in Label,
      where: l.user_id == ^user.id,
      order_by: l.name
    )
    |> Repo.all()
  end

  def get_or_create(user, label_name) do
    {:ok, label} = %Label{user: user, name: label_name} |> Repo.insert(on_conflict: :nothing)

    if is_nil(label.id) do
      Repo.get_by(Label, name: label_name)
    else
      label
    end
  end
end
