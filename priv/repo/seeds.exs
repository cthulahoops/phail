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
  {:ok, user} = Phail.Accounts.register_user(account)

  for mail_account <- Map.get(account, :mail_accounts, []) do
    Phail.MailAccount.create(Map.put(mail_account, :user_id, user.id))
  end
end
