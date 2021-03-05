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
    |> clear_suggestions
    |> ok
  end

  def mount(%{"reply_to" => reply_to}, _session, socket) do
    reply_to = Message.get(reply_to)

    socket
    |> assign(:reply_to, reply_to)
    |> new_reply(reply_to)
    |> clear_suggestions
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
    |> clear_suggestions
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
    socket
    |> add_to_address(Address.get(id))
    |> noreply
  end

  def handle_event("remove_to_address", %{"id" => id}, socket) do
    to_address = Address.get(id)

    socket
    |> update_message(fn message -> Message.remove_to_address(message, to_address) end)
    |> noreply
  end

  def handle_event("submit", _mail_data, socket) do
    # Message.send(socket.assigns.message)

    socket
    |> close
    |> noreply
  end


  def handle_event("handle_keydown", %{"key" => "Enter"}, socket) do
    socket
    |> add_to_address(Enum.fetch!(socket.assigns.suggestions, socket.assigns.add_to_index))
    |> noreply
  end

  def handle_event("handle_keydown", %{"key" => "Escape"}, socket) do
    clear_suggestions(socket)
    |> noreply
  end

  def handle_event("handle_keydown", %{"key" => key}, socket) do
    IO.puts(key)
    old_index = socket.assigns.add_to_index

    new_index = case key do
        "ArrowDown" -> old_index + 1
        "ArrowUp" -> old_index - 1
        _ -> old_index
      end

    new_index = clamp(new_index, 0, length(socket.assigns.suggestions) - 1)

    IO.inspect(new_index)

    socket
    |> assign(:add_to_index, new_index)
    |> noreply
  end

  defp clamp(x, min, _max) when x < min, do: min
  defp clamp(x, _min, max) when x > max, do: max
  defp clamp(x, _min, _max), do: x

  defp close(socket) do
    push_redirect(socket,
      to: Routes.phail_path(socket, :label, "Inbox")
    )
  end

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

  defp clear_suggestions(socket) do
    socket
    |> assign(:suggestions, [])
    |> assign(:add_to_index, 0)
  end

  defp add_to_address(socket, to_address) do
    socket
    |> update_message(fn message -> Message.add_to_address(message, to_address) end)
    |> assign(:add_to, "")
    |> update_suggestions("")
    |> clear_suggestions
  end

  defp ensure_message(socket) do
    if is_nil(socket.assigns.message.id) do
      message =
        Message.create(
          Conversation.create("Draft Message"),
          status: :draft
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

  def handle_info(_, socket) do
    noreply(socket)
  end
end
