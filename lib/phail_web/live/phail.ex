defmodule PhailWeb.Live.Phail do
  # alias Phail.Message
  alias Phail.Conversation
  use Phoenix.LiveView

  defp noreply(socket) do
    {:noreply, socket}
  end

  defp ok(socket) do
    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:conversations, [])
    |> assign(:expanded_id, nil)
    |> assign(:expanded_conversation, nil)
    |> assign(:search_filter, "")
    |> assign(:labels, Phail.Label.all())
    |> ok
  end

  def handle_params(%{"search_filter" => search_filter}, _uri, socket) do
    socket
    |> assign(:search_filter, search_filter)
    |> assign(:conversations, Conversation.search(search_filter))
    |> noreply
  end

  def handle_params(%{"label" => label}, _uri, socket) do
    socket
    |> assign(:search_filter, "")
    |> assign(:conversations, Conversation.search("label:" <> label))
    |> noreply
  end

  def handle_params(%{}, uri, socket) do
    handle_params(%{"search_filter" => ""}, uri, socket)
  end

  def handle_event("update_filter", %{"filter" => filter}, socket) do
    socket
    |> assign(:conversations, Conversation.search(filter))
    |> assign(:search_filter, filter)
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

  defp go_page(socket) do
    push_patch(socket,
      to: PhailWeb.Router.Helpers.phail_path(socket, :search, socket.assigns.search_filter)
    )
  end
end
