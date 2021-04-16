defmodule Phail.Reply do
  alias Phail.Message

  def create(reply_type, original_message = %Message{}) do
    Message.create(
      original_message.conversation,
      to: reply_to_addresses(original_message, reply_type),
      cc: reply_cc_addresses(original_message, reply_type),
      subject: subject_with_re_prefix(original_message.subject),
      status: "draft"
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
