defmodule :"Elixir.Phail.Repo.Migrations.ConversationLabelsPerUser.exs" do
  use Ecto.Migration

  def change do
    create unique_index(:labels, [:user_id, :name])
    drop unique_index(:labels, [:name])
  end
end
