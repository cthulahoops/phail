defmodule PhailWeb.Live.Compose do
  use PhailWeb, :live_view
  alias Phail.Message

  defp noreply(socket) do
    {:noreply, socket}
  end

  defp ok(socket) do
    {:ok, socket}
  end

  def mount(%{"message_id" => message_id}, _session, socket) do
    socket
    |> assign(:message, Message.get(message_id))
    |> ok
  end

  def mount(%{}, _session, socket) do
    socket
    |> assign(:message, %{:subject => "", :body => "", :id => nil})
    |> ok
  end

  def handle_params(_params, _session, socket) do
    # Everything should have been set-up for us already?
    noreply(socket)
  end

  def handle_event("save_draft", mail_data, socket) do
    socket
    |> save_message(mail_data)
    |> noreply
  end

  def handle_event("close", _mail_data, socket) do
    socket
    |> close
    |> noreply
  end

  def handle_event("discard_and_close", mail_data, socket) do
    Message.delete(socket.assigns.message)
    handle_event("close", mail_data, socket)
  end

  defp close(socket) do
    push_redirect(socket,
      to: Routes.phail_path(socket, :label, "Inbox")
    )
  end

  # def handle_event("send", _mail_data, socket) do
  #   socket
  #   |> noreply
  # end

  defp save_message(socket, %{"subject" => subject, "body" => body}) do
    message = socket.assigns.message

    if is_nil(message.id) do
      message = Message.create_draft([], [], [], subject, body)

      assign(socket, :message, message)
      |> push_patch(to: Routes.compose_path(socket, :message_id, message.id))
    else
      message = Message.update_draft(message, %{"subject" => subject, "body" => body})
      assign(socket, :message, message)
    end
  end
end
