defmodule PhailWeb.Live.Phail do
  use PhailWeb, :live_view
  alias PhailWeb.PhailView
  alias Phail.{Conversation, Message, Label}

  defp noreply(socket) do
    {:noreply, socket}
  end

  defp ok(socket) do
    {:ok, socket}
  end

  def mount(_params, session, socket) do
    socket = PhailWeb.LiveHelpers.assign_defaults(socket, session)

    socket
    |> assign(:expanded, nil)
    |> assign(
      :labels,
      Label.all(socket.assigns.current_user) |> Enum.filter(fn label -> label.name != "inbox" end)
    )
    |> ok
  end

  def handle_params(%{"search_filter" => search_filter}, _uri, socket) do
    socket
    |> assign(:search_filter, search_filter)
    |> assign(:label, nil)
    |> assign_conversations
    |> noreply
  end

  def handle_params(%{"label" => label}, _uri, socket) do
    socket
    |> assign(:search_filter, Phail.Query.format_label(label))
    |> assign(:label, label)
    |> assign_conversations
    |> noreply
  end

  def handle_params(%{"status" => message_status}, _uri, socket) do
    socket
    |> assign(:search_filter, Phail.Query.format_status(message_status))
    |> assign(:label, nil)
    |> assign_conversations
    |> noreply
  end

  def handle_params(%{}, uri, socket) do
    handle_params(%{"label" => "Inbox"}, uri, socket)
  end

  defp assign_conversations(socket) do
    assign(
      socket,
      :conversations,
      Conversation.search(socket.assigns.current_user, socket.assigns.search_filter)
    )
  end

  def handle_event("update_filter", %{"filter" => filter}, socket) do
    socket
    |> assign(:search_filter, filter)
    |> assign(:label, nil)
    |> assign_conversations
    |> update_url_with_search_filter
    |> noreply
  end

  def handle_event("expand", %{"id" => conversation_id}, socket) do
    if is_expanded(String.to_integer(conversation_id), socket.assigns.expanded) do
      socket |> assign(:expanded, nil)
    else
      socket |> assign(:expanded, Conversation.get(socket.assigns.current_user, conversation_id))
    end
    |> noreply
  end

  def handle_event("move", %{"id" => conversation_id, "target" => target}, socket) do
    change_labels(socket.assigns.current_user, conversation_id, socket.assigns.label, target)

    socket
    |> assign(:expanded, nil)
    |> assign_conversations
    |> noreply
  end

  def handle_event("remove_label", %{"id" => conversation_id}, socket) do
    conversation = Conversation.get(socket.assigns.current_user, conversation_id)
    if socket.assigns.label do
      Conversation.remove_label(conversation, socket.assigns.label)
    end

    socket
    |> assign(:expanded, nil)
    |> assign_conversations
    |> noreply
  end

  def handle_event("discard", %{"message_id" => message_id}, socket) do
    Message.get(socket.assigns.current_user, message_id) |> Message.delete()

    socket
    |> assign(:expanded, nil)
    |> assign_conversations
    |> noreply
  end

  defp change_labels(user, conversation_id, old_label, new_label) do
    conversation = Conversation.get(user, conversation_id)

    if old_label != nil do
      Conversation.remove_label(conversation, old_label)
    end

    Conversation.add_label(conversation, new_label)
  end

  defp update_url_with_search_filter(socket) do
    push_patch(socket,
      to: Routes.phail_path(socket, :search, socket.assigns.search_filter)
    )
  end

  def is_expanded(_conversation_id, nil), do: false

  def is_expanded(conversation_id, conversation) do
    conversation_id == conversation.id
  end
end
