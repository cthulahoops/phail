defmodule PhailWeb.Live.Compose do
  use PhailWeb, :live_view
  alias PhailWeb.PhailView
  alias Phail.{Address, Conversation, Message}

  defp noreply(socket) do
    {:noreply, socket}
  end

  defp ok(socket) do
    {:ok, socket}
  end

  def mount(%{"message_id" => message_id}, _session, socket) do
    message = Message.get(message_id)

    socket
    |> assign(:message, message)
    |> assign(:conversation, Conversation.get(message.conversation.id))
    |> assign(:add_to, "")
    |> assign(:suggestions, [])
    |> ok
  end

  def mount(%{"reply_to" => reply_to}, _session, socket) do
    reply_to = Message.get(reply_to)

    socket
    |> assign(:reply_to, reply_to)
    |> new_reply(reply_to)
    |> assign(:suggestions, [])
    |> ok
  end

  def mount(%{}, _session, socket) do
    socket
    |> assign(:message, %{
      :subject => "",
      :body => "",
      :id => nil,
      :to_addresses => []
    })
    |> assign(:conversation, nil)
    |> assign(:add_to, "")
    |> assign(:suggestions, [])
    |> ok
  end

  def handle_params(_params, _session, socket) do
    # Everything should have been set-up for us already?
    noreply(socket)
  end

  def handle_event("change", mail_data = %{"add_to" => add_to}, socket) do
    socket
    |> update_suggestions(add_to)
    |> update_message(fn message -> Message.update_draft(message, mail_data) end)
    |> noreply
  end

  def handle_event("close", _mail_data, socket) do
    socket
    |> close
    |> noreply
  end

  def handle_event("discard_and_close", mail_data, socket) do
    if !is_nil(socket.assigns.message.id) do
      Message.delete(socket.assigns.message)
    end

    handle_event("close", mail_data, socket)
  end

  def handle_event("add_to", %{"id" => id}, socket) do
    to_address = Address.get(id)

    socket
    |> update_message(fn message -> Message.add_to_address(message, to_address) end)
    |> update_suggestions("")
    |> noreply
  end

  def handle_event("remove_to_address", %{"id" => id}, socket) do
    to_address = Address.get(id)

    socket
    |> update_message(fn message -> Message.remove_to_address(message, to_address) end)
    |> noreply
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
  #
  defp update_suggestions(socket, add_to) do
    update_suggestions(socket, add_to, socket.assigns.add_to)
  end

  defp update_suggestions(socket, add_to, add_to) do
    socket
  end

  defp update_suggestions(socket, "", _last_add_to) do
    socket
    |> assign(:suggestions, [])
    |> assign(:add_to, "")
  end

  defp update_suggestions(socket, add_to, _last_add_to) do
    socket
    |> assign(:suggestions, Address.prefix_search(add_to))
    |> assign(:add_to, add_to)
  end

  defp ensure_message(socket) do
    if is_nil(socket.assigns.message.id) do
      message =
        Message.create(
          Conversation.create("Draft Message"),
          is_draft: true
        )

      assign(socket, :message, message)
      |> push_patch(to: Routes.compose_path(socket, :message_id, message.id))
    else
      socket
    end
  end

  defp update_message(socket, fun) do
    socket = ensure_message(socket)
    assign(socket, :message, fun.(socket.assigns.message))
  end

  defp new_reply(socket, reply_to) do
    message = Phail.Reply.create(reply_to)

    assign(socket, :message, message)
    |> push_redirect(to: Routes.compose_path(socket, :reply_to_draft, reply_to.id, message.id))
  end
end
