defmodule PhailWeb.Live.Compose do
  use PhailWeb, :live_view
  alias Phail.{Address, Message}

  defp noreply(socket) do
    {:noreply, socket}
  end

  defp ok(socket) do
    {:ok, socket}
  end

  def mount(%{"message_id" => message_id}, _session, socket) do
    socket
    |> assign(:message, Message.get(message_id))
    |> assign(:add_to, "")
    |> assign(:suggestions, [])
    |> assign(:to_addresses, [])
    |> ok
  end

  def mount(%{}, _session, socket) do
    socket
    |> assign(:message, %{:subject => "", :body => "", :id => nil, :to_addresses => []})
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
    |> update_suggestions(add_to, socket.assigns.add_to)
    |> save_message(mail_data)
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
    |> add_to_address(Address.get(String.to_integer(id)), socket.assigns.message)
    |> update_suggestions("", socket.assigns.add_to)
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

  defp add_to_address(socket, to_address = %Address{}) do
    add_to_address(socket, to_address, socket.assigns.message)
  end

  defp add_to_address(socket, to_address = %Address{}, %{:id => nil}) do
    save_message(socket, %{"subject" => "", "body" => ""})
    add_to_address(socket, to_address)
  end

  defp add_to_address(socket, to_address = %Address{}, message = %Message{}) do
    updated_message = Message.add_to_address(message, to_address)

    socket
    |> assign(:message, updated_message)
  end
end
