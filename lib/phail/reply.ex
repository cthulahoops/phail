defmodule Phail.Reply do
  alias Phail.Message

  def create(user, reply_type, original_message = %Message{}) do
    mail_account = Phail.MailAccount.get_by_user(user)

    Message.create_draft(
      original_message.conversation,
      mail_account,
      to: reply_to_addresses(original_message, reply_type),
      cc: reply_cc_addresses(original_message, reply_type),
      subject: subject_with_re_prefix(original_message.subject),
      references: [original_message.message_id | Message.references(original_message)],
      in_reply_to: original_message.message_id
    )
  end

  # Handle:
  #
  #   reply_to header
  #   reply_alling ourselves.
  #
  defp reply_to_addresses(original_message, _) do
    Message.from_addresses(original_message)
  end

  defp reply_cc_addresses(_original_message, "one"), do: []

  defp reply_cc_addresses(original_message, "all") do
    Message.cc_addresses(original_message)
  end

  defp subject_with_re_prefix(subject) do
    if String.starts_with?(subject, "Re:") do
      subject
    else
      "Re: " <> subject
    end
  end
end
