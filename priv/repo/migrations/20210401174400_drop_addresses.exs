defmodule Phail.Repo.Migrations.DropAddresses do
  use Ecto.Migration

  def change do
    drop table(:message_from_address)
    drop table(:message_to_address)
    drop table(:message_cc_address)
    drop table(:addresses)
  end
end
