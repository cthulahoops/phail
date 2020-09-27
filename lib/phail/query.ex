defmodule Phail.Query do
  use Combine
  defstruct labels: [], text_terms: [], statuses: []

  def parse(query_string) do
    query_terms = hd(Combine.parse(query_string, parser()))

    Enum.reduce(
      query_terms,
      %Phail.Query{},
      fn
        {:label, label_name}, query -> %{query | labels: query.labels ++ [label_name]}
        {:text, text}, query -> %{query | text_terms: query.text_terms ++ [text]}
        {:status, status}, query -> %{query | statuses: query.statuses ++ [status]}
      end
    )
  end

  defp parser() do
    between(
      option(spaces()),
      sep_by(search_term(), spaces()),
      option(spaces())
    )
    |> eof
  end

  defp search_term(previous \\ nil) do
    previous
    |> choice([label(), status(), text_term()])
  end

  defp text_term(previous \\ nil) do
    previous
    |> word_of(~r/[^ :]/)
    |> map(fn x -> {:text, x} end)
  end

  defp label(previous \\ nil) do
    previous
    |> pair_right(string("label:"), label_name())
    |> map(fn x -> {:label, x} end)
  end

  defp label_name(parser \\ nil) do
    parser |> either(quoted_string(), word())
  end

  defp status(previous \\ nil) do
    previous
    |> pair_right(string("is:"), message_status())
    |> map(fn x -> {:status, String.to_existing_atom(x)} end)
  end

  defp message_status(previous \\ nil) do
    previous
    |> one_of(word(), ["draft", "outbox", "sent"])
  end

  defp quoted_string(parser \\ nil) do
    between(parser, char("\""), word_of(~r/[^"]/), char("\""))
  end

  def format(query) do
    Enum.join(
      Enum.map(query.labels, &format_label/1) ++
        Enum.map(query.statuses, &format_status/1) ++ query.text_terms,
      " "
    )
  end

  def format_label(label_name) do
    quoted_label_name =
      if String.match?(label_name, ~r/^\w*$/) do
        label_name
      else
        "\"" <> label_name <> "\""
      end

    "label:" <> quoted_label_name
  end

  defp format_status(status) do
    "is:" <> Atom.to_string(status)
  end
end
