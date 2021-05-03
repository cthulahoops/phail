defmodule PhailWeb.PhailView do
  use PhailWeb, :view

  def conversation_senders(addresses) do
    assigns = %{}

    uniq_addresses = Enum.uniq_by(addresses, fn address -> address.address end)
    count = Enum.count(addresses)

    ~L"""
        <div class="sender-list">
        <ul class="comma-separated">
        <%= if length(uniq_addresses) == 1 do %>
          <li><%= address_name hd(uniq_addresses) %></li>
        <% else %>
          <%= for address <- uniq_addresses do %>
            <li><%= address_short address %></li>
          <% end %>
        <% end %>
        </ul>
        <%= if Enum.count(addresses) > Enum.count(uniq_addresses) do %>
          <span class="less-important-text">
          <%= count %>
          </span>
        <% end %>
        </div>
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
    assigns = %{id: id, addresses: addresses, suggestions: suggestions}

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
          <li x-spread="suggestion( <%= idx %> )" suggestion-id="<%= suggestion.id %>">
            <%= format_address suggestion %>
          </li>
        <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  def format_address(%{address: address, name: ""}), do: address
  def format_address(%{address: address, name: name}), do: name <> " <" <> address <> ">"

  def address_name(%{address: address, name: ""}), do: address
  def address_name(%{name: name}), do: name

  def address_short(%{address: address, name: ""}), do: address
  def address_short(%{name: name}), do: hd(String.split(name, " "))

  def navigation(socket, type, text) when is_atom(type) do
    live_patch(to: Routes.phail_path(socket, type)) do
      text
    end
  end

  def navigation(socket, {type, arg}, text) do
    live_patch(to: Routes.phail_path(socket, type, arg)) do
      text
    end
  end

  def label_navigation(socket, label_name, opts \\ []) do
    live_patch(Keyword.put(opts, :to, Routes.phail_path(socket, :label, label_name))) do
      label_name
    end
  end
end
