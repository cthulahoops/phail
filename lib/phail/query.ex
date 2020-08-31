defmodule Phail.Query do
  use Combine
  defstruct labels: [], text_terms: []

  def parse(query_string) do
    query_terms = hd(Combine.parse(query_string, parser()))

    Enum.reduce(
      query_terms,
      %Phail.Query{},
      fn
        {:label, label_name}, query -> %{query | labels: query.labels ++ [label_name]}
        {:text, text}, query -> %{query | text_terms: query.text_terms ++ [text]}
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
    |> either(label(), text_term())
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

  defp quoted_string(parser \\ nil) do
    between(parser, char("\""), word_of(~r/[^"]/), char("\""))
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

  def format(query) do
    Enum.join(Enum.map(query.labels, &format_label/1) ++ query.text_terms, " ")
  end
end
