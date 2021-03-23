defmodule Phail.Repo.Migrations.ConversationDraft do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :is_draft, :boolean, default: false, null: false
    end
  end
end
