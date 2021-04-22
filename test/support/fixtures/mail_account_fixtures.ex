defmodule Phail.MailAccountsFixtures do
  def mail_account_fixture(user) do
    Phail.MailAccount.create(%{
      user_id: user.id,
      email: user.email,
      name: "Whatever"
    })
  end
end
