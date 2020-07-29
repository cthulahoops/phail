defmodule PhailWeb.Live.Phail do
 # alias Phail.Message
  alias Phail.Conversation
  use Phoenix.LiveView

  defp noreply(socket) do
    {:noreply, socket}
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conversations, Conversation.all())
     |> assign(:expanded_id, nil)
     |> assign(:expanded_conversation, nil)
     |> assign(:search_filter, "")}
  end

  def handle_event("update_filter", %{"filter" => filter}, socket) do
    socket
    |> assign(:conversations, Conversation.search(filter))
    |> assign(:search_filter, filter)
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
    end |> noreply
  end

  def render(assigns) do
    ~L"""
    <form phx-submit="update_filter">
      <input name=filter placeholder="Search mail..." value="<%= @search_filter %>"</input>
    </form>

    <ul class=mailbox>
    <%= for conversation <- @conversations do %>
      <li phx-value-id="<%= conversation.id %>" class="conversation" phx-click="expand">
        <%= conversation.id %>
        <span class=subject><%= conversation.subject %></span>
        <%= if conversation.id == @expanded_id do %>
          <%= for message <- @expanded_conversation.messages do %>
          <div class=message>
            <ul>
            <li>
            From:
            <%= for address <- message.from_addresses do %>
               <span class=address title="<%= address.address %>"><%= Phail.Address.display address %></span>
            <% end %>
            </li>
            <li>
            To:
            <%= for address <- message.to_addresses do %>
               <span class=address title="<%= address.address %>"><%= Phail.Address.display address %></span>
            <% end %>
            </li>
            <%= if message.cc_addresses != [] do %>
            <li>
            Cc:
            <%= for address <- message.cc_addresses do %>
               <span class=address title="<%= address.address %>"><%= Phail.Address.display address %></span>
            <% end %>
            <% end %>
            </li>
            <li>
            Date: <%= message.date %>
            </li>
            </ul>

            <div class=body>
            <%= Phoenix.HTML.raw message.body %>
            </div>
          </div>
          <% end %>
        <% end %>
      </li>
    <% end %>
    </ul>
    """

  end
end
