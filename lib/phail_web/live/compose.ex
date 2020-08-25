defmodule PhailWeb.Live.Compose do
  use Phoenix.LiveView
  alias Phail.Message

  defp noreply(socket) do
    {:noreply, socket}
  end

  defp ok(socket) do
    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:message, :nil)
    |> ok
  end

  def handle_event("save_draft", mail_data, socket) do
    message = save_message(mail_data, socket.assigns.message)
    socket
    |> assign(:message, message)
    |> noreply
  end

  def handle_event("submit", mail_data, socket) do
    save_message(mail_data, socket.assigns.message)
    push_redirect(socket,
      to: PhailWeb.Router.Helpers.phail_path(socket, :label, "Inbox")
    )
    |> noreply
  end

  # def handle_event("send", _mail_data, socket) do
  #   socket
  #   |> noreply
  # end

  defp save_message(%{"subject" => subject, "body" => body}, message) do
    if is_nil(message) do
      Message.create_draft([], [], [], subject, body)
    else
      Message.update_draft(message, %{"subject" => subject, "body" => body})
    end
  end

end
