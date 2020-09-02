defmodule PhailWeb.PhailView do
  use PhailWeb, :view
  alias Phail.Address

  def name_list(addresses) do
    assigns = %{addresses: addresses}

    ~L"""
        <ul class="sender_list comma_separated">
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
    <ul class="comma_separated">
      <%= for address <- addresses do %>
         <li title="<%= address.address %>"><%= format_address address %></li>
      <% end %>
    </ul>
    """
  end

  def format_address(%Address{address: address, name: ""}), do: address
  def format_address(%Address{address: address, name: name}), do: name <> " <" <> address <> ">"

  def address_name(%Address{address: address, name: ""}), do: address
  def address_name(%Address{name: name}), do: name

  def address_short(%Address{address: address, name: ""}), do: address
  def address_short(%Address{name: name}), do: hd(String.split(name, " "))
end
