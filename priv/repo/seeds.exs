# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Phail.Repo.insert!(%Phail.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

for account <- Application.get_env(:phail, :default_accounts, []) do
  Phail.Accounts.register_user(account)
end
