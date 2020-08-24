defmodule PhailWeb.Live.Phail do
  # alias Phail.Message
  alias Phail.Conversation
  alias Phail.Label
  use Phoenix.LiveView

  defp noreply(socket) do
    {:noreply, socket}
  end

  defp ok(socket) do
    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:expanded_id, nil)
    |> assign(:expanded_conversation, nil)
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
    |> assign(:search_filter, "")
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

  defp get_conversations(%{:label => label}) when is_binary(label) do
      Conversation.search("label:" <> label)
  end

  defp assign_conversations(socket) do
    assign(socket, :conversations, get_conversations(socket.assigns))
  end

  def handle_event("update_filter", %{"filter" => filter}, socket) do
    socket
    |> assign(:search_filter, filter)
    |> assign(:label, :nil)
    |> assign_conversations
    |> go_page
    |> noreply
  end

  def handle_event("expand", %{"id" => conversation_id}, socket) do
    conversation_id = String.to_integer(conversation_id)

    if conversation_id == socket.assigns.expanded_id do
      socket
      |> assign(:expanded_id, nil)
      |> assign(:expanded_conversation, nil)
    else
      conversation = Conversation.get(conversation_id)

      socket
      |> assign(:expanded_id, conversation.id)
      |> assign(:expanded_conversation, conversation)
    end
    |> noreply
  end

  def handle_event("move", %{"id" => conversation_id, "target" => target}, socket) do
    change_labels(conversation_id, socket.assigns.label, target)
    socket
    |> assign_conversations
    |> noreply
  end

  defp change_labels(conversation_id, old_label, new_label) do
    conversation_id = String.to_integer(conversation_id)

    if old_label != :nil do
      Conversation.remove_label(conversation_id, old_label)
    end
    conversation = Conversation.get(conversation_id)
    Conversation.add_label(conversation, new_label)
  end

  defp go_page(socket) do
    push_patch(socket,
      to: PhailWeb.Router.Helpers.phail_path(socket, :search, socket.assigns.search_filter)
    )
  end
end
