defmodule PhailWeb.Live.Compose do
  use PhailWeb, :live_view
  alias PhailWeb.PhailView
  alias Phail.{Conversation, Message, MessageAddress}
  alias PhailWeb.LiveHelpers

  defp noreply(socket) do
    {:noreply, socket}
  end

  defp ok(socket) do
    {:ok, socket}
  end

  defmodule AddressInput do
    defstruct suggestions: [], input_value: ""
  end

  def mount(params, session, socket) do
    mount(params, LiveHelpers.assign_defaults(socket, session))
  end

  defp mount(%{"message_id" => message_id}, socket) do
    message = Message.get(socket.assigns.current_user, message_id)

    socket
    |> assign(:message, message)
    |> assign(
      :conversation,
      Conversation.get(socket.assigns.current_user, message.conversation.id)
    )
    |> assign(:to_input, %AddressInput{})
    |> assign(:cc_input, %AddressInput{})
    |> ok
  end

  defp mount(%{"reply_type" => reply_type, "reply_to" => reply_to}, socket) do
    reply_to = Message.get(socket.assigns.current_user, reply_to)

    socket
    |> assign(:reply_to, reply_to)
    |> new_reply(reply_type, reply_to)
    |> ok
  end

  defp mount(%{}, socket) do
    socket
    |> assign(:message, %{
      :subject => "",
      :body => "",
      :id => nil,
      :message_addresses => []
    })
    |> assign(:conversation, nil)
    |> assign(:to_input, %AddressInput{})
    |> assign(:cc_input, %AddressInput{})
    |> ok
  end

  def handle_params(_params, _session, socket) do
    # Everything should have been set-up for us already?
    noreply(socket)
  end

  def handle_event("change", mail_data, socket) do
    socket = socket |> update_suggestions(mail_data)

    if mail_data["subject"] != "" or mail_data["body"] != "" do
      socket |> update_message(fn message -> Message.update_draft(message, mail_data) end)
    else
      socket
    end
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

  def handle_event("add_address", %{"input_id" => input_id, "id" => id}, socket) do
    socket
    |> add_address(address_type(input_id), MessageAddress.get(socket.assigns.current_user, id))
    |> update_suggestions(input_id, "")
    |> noreply
  end

  def handle_event(
        "add_address",
        %{"input_id" => input_id, "address" => address, "name" => name},
        socket
      ) do
    socket
    |> add_address(address_type(input_id), %{address: address, name: name})
    |> update_suggestions(input_id, "")
    |> noreply
  end

  def handle_event("remove_address", %{"input_id" => _input_id, "id" => address_id}, socket) do
    socket
    |> update_message(fn message -> Message.remove_address(message, address_id) end)
    |> noreply
  end

  def handle_event("submit", _mail_data, socket) do
    Message.send(socket.assigns.message)

    socket
    |> close
    |> noreply
  end

  def handle_event("clear_suggestions", %{"input_id" => input_id}, socket) do
    socket
    |> update_suggestions(input_id, "")
    |> noreply
  end

  defp close(socket) do
    push_redirect(socket,
      to: Routes.phail_path(socket, :label, "Inbox")
    )
  end

  defp update_suggestions(socket, %{"to" => input_value, "_target" => ["to"]}) do
    update_suggestions(socket, :to_input, input_value)
  end

  defp update_suggestions(socket, %{"cc" => input_value, "_target" => ["cc"]}) do
    update_suggestions(socket, :cc_input, input_value)
  end

  defp update_suggestions(socket, %{}) do
    socket
  end

  defp update_suggestions(socket, "to_input", input_value) do
    update_suggestions(socket, :to_input, input_value)
  end

  defp update_suggestions(socket, "cc_input", input_value) do
    update_suggestions(socket, :cc_input, input_value)
  end

  defp update_suggestions(socket, input, input_value) do
    update_suggestions(socket, input, input_value, socket.assigns[input].input_value)
  end

  defp update_suggestions(socket, _input, input_value, last_input_value)
       when input_value == last_input_value do
    socket
  end

  defp update_suggestions(socket, input, input_value, _last_input_value) do
    socket
    |> assign(input, %AddressInput{
      suggestions: MessageAddress.prefix_search(socket.assigns.current_user, input_value),
      input_value: input_value
    })
  end

  defp add_address(socket, address_type, to_address) do
    socket
    |> update_message(fn message -> Message.add_address(message, address_type, to_address) end)
  end

  defp ensure_message(socket) do
    if is_nil(socket.assigns.message.id) do
      message =
        Message.create_draft(
          Conversation.create(socket.assigns.current_user, "Draft Message"),
          Phail.MailAccount.get_by_user(socket.assigns.current_user)
        )

      socket
      |> assign(:message, message)
      |> push_patch(to: Routes.compose_path(socket, :message_id, message.id))
    else
      socket
    end
  end

  defp update_message(socket, fun) do
    socket = ensure_message(socket)
    assign(socket, :message, fun.(socket.assigns.message))
  end

  defp new_reply(socket, reply_type, reply_to) do
    message = Phail.Reply.create(socket.assigns.current_user, reply_type, reply_to)

    assign(socket, :message, message)
    |> push_redirect(to: Routes.compose_path(socket, :message_id, message.id))
  end

  def handle_info(_, socket) do
    noreply(socket)
  end

  defp address_type("to_input"), do: :to
  defp address_type("cc_input"), do: :cc
end
