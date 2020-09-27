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

  def mount(_params, _session, socket) do
    socket
    |> assign(:expanded, nil)
    |> assign(:labels, Label.all())
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

  def handle_params(%{}, uri, socket) do
    handle_params(%{"label" => "Inbox"}, uri, socket)
  end

  defp get_conversations(%{:label => nil, :search_filter => search_filter}) do
    Conversation.search(search_filter)
  end

  defp get_conversations(%{:label => "Drafts"}) do
    Conversation.select_drafts()
  end

  defp get_conversations(%{:label => label}) when is_binary(label) do
    Conversation.select_by_label(label)
  end

  defp assign_conversations(socket) do
    assign(socket, :conversations, get_conversations(socket.assigns))
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
      socket |> assign(:expanded, Conversation.get(conversation_id))
    end
    |> noreply
  end

  def handle_event("move", %{"id" => conversation_id, "target" => target}, socket) do
    change_labels(conversation_id, socket.assigns.label, target)

    socket
    |> assign(:expanded, nil)
    |> assign_conversations
    |> noreply
  end

  def handle_event("discard", %{"message_id" => message_id}, socket) do
    Message.get(message_id) |> Message.delete()

    socket
    |> assign(:expanded, nil)
    |> assign_conversations
    |> noreply
  end

  defp change_labels(conversation_id, old_label, new_label) do
    conversation = Conversation.get(conversation_id)

    if old_label != nil do
      Conversation.remove_label(conversation.id, old_label)
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
