defmodule PhailWeb.Live.Conversation do
  use PhailWeb, :live_component
  alias PhailWeb.PhailView

  defp noreply(socket) do
    {:noreply, socket}
  end

  defp ok(socket) do
    {:ok, socket}
  end

  def mount(socket) do
    socket
    |> assign(:hidden, MapSet.new())
    |> ok
  end

  def handle_event("toggle_hide", %{"message-id" => message_id}, socket) do
    socket
    |> assign(:hidden, toggle_hidden(socket.assigns.hidden, message_id))
    |> noreply
  end

  defp hidden?(hidden, message_id) do
    MapSet.member?(hidden, message_id)
  end

  defp toggle_hidden(hidden, message_id) when is_binary(message_id) do
    toggle_hidden(hidden, String.to_integer(message_id))
  end

  defp toggle_hidden(hidden, message_id) when is_integer(message_id) do
    if MapSet.member?(hidden, message_id) do
      MapSet.delete(hidden, message_id)
    else
      MapSet.put(hidden, message_id)
    end
  end
end
