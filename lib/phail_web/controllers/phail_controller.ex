defmodule PhailWeb.PhailController do
  use PhailWeb, :controller

  def original(conn, %{"message_id" => message_id}) do
    original = Phail.Original.get(conn.assigns.current_user, message_id)
    render(conn, "original.html", message_id: message_id, original: original)
  end
end
