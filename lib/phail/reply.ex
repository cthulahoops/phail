defmodule Phail.Reply do
  alias Phail.Message

  def create(original_message = %Message{}) do
    Message.create(
      original_message.conversation,
      to: Message.from_addresses(original_message),
      subject: subject_with_re_prefix(original_message.subject),
      status: "draft"
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
