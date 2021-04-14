defmodule Phail.Original do
  use Ecto.Schema
  import Ecto.Query
  alias Phail.Repo
  alias Phail.Original

  schema "originals" do
    field(:text, :binary)

    belongs_to(:user, Phail.Accounts.User)
    belongs_to(:message, Phail.Message)
  end

  def get(user, id) do
    Original
    |> where([o], o.user_id == ^user.id)
    |> Repo.get!(id)
  end
end
