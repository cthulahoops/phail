defmodule PhailWeb.Live.Phail do
  alias Phail.Message
  use Phoenix.LiveView

  defp noreply(socket) do
    {:noreply, socket}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:messages, Message.all())}
  end

  def handle_event("update_filter", %{"filter" => filter}, socket) do
    socket
    |> assign(:messages, Phail.Message.search(filter))
    |> noreply
  end

  def render(assigns) do
    ~L"""
    <form phx-submit="update_filter">
      <input name=filter placeholder="Search mail..." value=""</input>
    </form>

    <ul class=mailbox>
    <%= for message <- @messages do %>
      <li id="message_<%= message.id %>" class="conversation">
        <%= for from <- message.from_addresses do %>
            <span class=from title=<%= from.address %>><%= from.name %></span>
        <% end %>
        <span class=subject><%= message.subject %></span>
      </li>
    <% end %>
    </ul>
    """
  end
end
