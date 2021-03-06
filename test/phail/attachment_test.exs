defmodule Phail.AttachmentTest do
  use Phail.DataCase

  alias Phail.Attachment

  import Phail.AccountsFixtures
  import Phail.ConversationFixtures

  describe "file" do
    alias Phail.Attachment.File

    @valid_attrs %{
      data: "some data",
      content_type: "some content_type",
      disposition: :attachment,
      filename: "somefile.txt"
    }
    @update_attrs %{
      data: "some updated data",
      content_type: "some updated content_type",
      disposition: :inline,
      filename: "other.txt"
    }
    @invalid_attrs %{data: nil, content_type: nil, disposition: :other}

    def message_fixture() do
      message_fixture(user_fixture())
    end

    def message_fixture(user) do
      hd(conversation_fixture(user).messages)
    end

    def file_fixture() do
      file_fixture(user_fixture())
    end

    def file_fixture(user, attrs \\ %{}) do
      {:ok, file} = Attachment.create_file(message_fixture(user), Enum.into(attrs, @valid_attrs))
      file
    end

    test "list_file/0 returns all file" do
      user = user_fixture()
      file = file_fixture(user)
      assert Attachment.list_file(user) == [file]
    end

    test "get_file!/1 returns the file with given id" do
      user = user_fixture()
      file = file_fixture(user)
      assert Attachment.get_file!(user, file.id) == file
    end

    test "create_file/1 with valid data creates a file" do
      user = user_fixture()
      message = message_fixture(user)
      assert {:ok, %File{} = file} = Attachment.create_file(message, @valid_attrs)
      assert file.data == "some data"
      assert file.content_type == "some content_type"
      assert file.message_id == message.id
      assert file.user_id == message.user_id
    end

    test "create_file/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Attachment.create_file(message_fixture(), @invalid_attrs)
    end

    test "update_file/2 with valid data updates the file" do
      file = file_fixture()
      assert {:ok, %File{} = file} = Attachment.update_file(file, @update_attrs)
      assert file.data == "some updated data"
      assert file.content_type == "some updated content_type"
    end

    test "update_file/2 with invalid data returns error changeset" do
      user = user_fixture()
      file = file_fixture(user)
      assert {:error, %Ecto.Changeset{}} = Attachment.update_file(file, @invalid_attrs)
      assert file == Attachment.get_file!(user, file.id)
    end

    test "delete_file/1 deletes the file" do
      user = user_fixture()
      file = file_fixture(user)
      assert {:ok, %File{}} = Attachment.delete_file(file)
      assert_raise Ecto.NoResultsError, fn -> Attachment.get_file!(user, file.id) end
    end

    test "change_file/1 returns a file changeset" do
      file = file_fixture()
      assert %Ecto.Changeset{} = Attachment.change_file(file)
    end
  end
end
