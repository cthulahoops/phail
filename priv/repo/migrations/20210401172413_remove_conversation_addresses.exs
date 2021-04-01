defmodule Phail.Repo.Migrations.RemoveConversationAddresses do
  use Ecto.Migration

  def change do
    drop table(:conversation_from_address)
  end
end
