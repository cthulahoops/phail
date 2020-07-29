defmodule Phail.TextSearch do
  defmacro fulltext(columns, query) do
    quote do
      atat(to_tsvector(unquote(columns)), to_tsquery(unquote(query)))
    end
  end

  defmacro to_tsvector(fields) do
    quote do
      fragment("to_tsvector('english', ?)", unquote(fields))
    end
  end

  defmacro space_join(left, right) do
    quote do
      fragment("? || ' ' || ?", unquote(left), unquote(right))
    end
  end

  defmacro to_tsquery(query) do
    quote do
      fragment("to_tsquery('english', ?)", unquote(query))
    end
  end

  defmacro atat(left, right) do
    quote do
      fragment("? @@ ?", unquote(left), unquote(right))
    end
  end
end
