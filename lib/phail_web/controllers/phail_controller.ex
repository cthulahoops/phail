defmodule PhailWeb.PhailController do
  use PhailWeb, :controller

  def original(conn, %{"message_id" => message_id}) do
    original = Phail.Original.get(conn.assigns.current_user, message_id)
    render(conn, "original.html", message_id: message_id, original: original)
  end

  def attachment(conn, %{"file_id" => file_id}) do
    file = Phail.Attachment.get_file!(conn.assigns.current_user, file_id)
    send_download(
      conn,
      {:binary, file.data},
      filename: file.filename,
      content_type: file.content_type,
      disposition: file.disposition
    )
  end
end
