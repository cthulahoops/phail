defmodule MessageTest do
     use ExUnit.Case
     alias Phail.Repo
     alias Phail.{Conversation, Message}
    
     setup do
       :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
     end
end
