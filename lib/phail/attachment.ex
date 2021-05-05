defmodule Phail.Attachment do
  @moduledoc """
  The Attachment context.
  """

  import Ecto.Query, warn: false
  alias Phail.Repo

  alias Phail.Attachment.File

  @doc """
  Returns the list of file.

  ## Examples

      iex> list_file(user)
      [%File{}, ...]

  """
  def list_file(user) do
    File |> where([f], f.user_id == ^user.id) |> Repo.all()
  end

  @doc """
  Gets a single file.

  Raises `Ecto.NoResultsError` if the File does not exist.

  ## Examples

      iex> get_file!(user, 123)
      %File{}

      iex> get_file!(user, 456)
      ** (Ecto.NoResultsError)

  """
  def get_file!(user, id), do: File |> where([f], f.user_id == ^user.id) |> Repo.get!(id)

  @doc """
  Creates a file.

  ## Examples

      iex> create_file(%{field: value})
      {:ok, %File{}}

      iex> create_file(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_file(message, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{message_id: message.id, user_id: message.user_id})

    %File{}
    |> File.changeset(attrs)
    |> Repo.insert()
  end

  def get_message_files(message = %Phail.Message{}) do
    File
    |> where([f], f.message_id == ^message.id)
    |> Repo.all()
  end

  @doc """
  Updates a file.

  ## Examples

      iex> update_file(file, %{field: new_value})
      {:ok, %File{}}

      iex> update_file(file, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_file(%File{} = file, attrs) do
    file
    |> File.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a file.

  ## Examples

      iex> delete_file(file)
      {:ok, %File{}}

      iex> delete_file(file)
      {:error, %Ecto.Changeset{}}

  """
  def delete_file(%File{} = file) do
    Repo.delete(file)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking file changes.

  ## Examples

      iex> change_file(file)
      %Ecto.Changeset{data: %File{}}

  """
  def change_file(%File{} = file, attrs \\ %{}) do
    File.changeset(file, attrs)
  end

  def is_image(%File{content_type: content_type}) do
    String.starts_with?(content_type, "image/")
  end
end
