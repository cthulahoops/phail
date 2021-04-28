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

  def get(user, message_id) do
    Original
    |> where([o], o.user_id == ^user.id and o.message_id == ^message_id)
    |> Repo.one!()
  end

  def save(%{id: id, user_id: user_id}, raw_msg) do
    %Original{
      message_id: id,
      user_id: user_id,
      text: raw_msg
    }
    |> Repo.insert!()
  end
end
