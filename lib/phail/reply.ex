defmodule Phail.Reply do
  alias Phail.Message

  def create(original_message=%Message{}) do
    Message.create(
      original_message.conversation,
      to: original_message.from_addresses,
      subject: subject_with_re_prefix(original_message.subject),
      is_draft: true
    )
  end

  defp subject_with_re_prefix(subject) do
    if String.starts_with?(subject, "Re:") do
      subject
    else
      "Re: " <> subject
    end
  end
end
