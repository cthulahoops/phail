defmodule PhailWeb.PhailView do
  use PhailWeb, :view
  alias Phail.Address

  def name_list(addresses) do
    assigns = %{addresses: addresses}

    ~L"""
        <ul class="sender-list comma-separated">
        <%= if length(addresses) == 1 do %>
          <li><%= address_name hd(addresses) %></li>
        <% else %>
          <%= for address <- addresses do %>
            <li><%= address_short address %></li>
          <% end %>
        <% end %>
        </ul>
    """
  end

  def address_list(addresses) do
    assigns = %{}

    ~L"""
    <ul class="comma-separated">
      <%= for address <- addresses do %>
         <li title="<%= address.address %>"><%= format_address address %></li>
      <% end %>
    </ul>
    """
  end

  def address_input(id, addresses, suggestions) do
    assigns = %{ id: id, addresses: addresses, suggestions: suggestions }
    ~L"""
    <div id="<%= id %>_input" x-on:click="$refs.inputElement.focus()"class="address-input input" x-data="multiInput()" phx-hook="PushEvent" phx-push-event="add_address,remove_address,clear_suggestions">
    <%= for address <- @addresses do %>
      <div id="address-<%= id %>-<%= address.id %>" class="message-recipient" title="<%= format_address address %>">
        <%= address_name address %>
        <a class="cross-icon" title="Remove Address" phx-click="remove_address" phx-value-input_id="<%= id %>_input" phx-value-id="<%= address.id %>"></a>
      </div>
    <% end %>
    <div class="autocomplete">
      <input
        name="<%= id %>"
        id="<%= id %>"
        type=text
        autocomplete="off"
        value=""
        x-spread="input"
        x-ref="inputElement"
        >
      <%= if @suggestions != [] do %>
        <ul x-ref="suggestions" x-show.transition="showSuggestions" class="autocomplete_suggestions">
        <%= for {suggestion, idx} <- Enum.with_index(@suggestions) do %>
          <li id="suggestion-<%= id %>-<%= suggestion.id %>" x-spread="suggestion( <%= idx %> )" suggestion-id="<%= suggestion.id %>">
            <%= format_address suggestion %>
          </li>
        <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  def format_address(%Address{address: address, name: ""}), do: address
  def format_address(%Address{address: address, name: name}), do: name <> " <" <> address <> ">"

  def address_name(%Address{address: address, name: ""}), do: address
  def address_name(%Address{name: name}), do: name

  def address_short(%Address{address: address, name: ""}), do: address
  def address_short(%Address{name: name}), do: hd(String.split(name, " "))
end
