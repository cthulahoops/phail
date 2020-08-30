defmodule Phail.Query do
  use Combine
  defstruct labels: [], text: ""

  def parse(query_string) do
    query_terms = hd(Combine.parse(query_string, parser()))
    text_terms = for {:text, text} <- query_terms, do: text
    text = Enum.join(text_terms, " & ")
    labels = for {:label, label_name} <- query_terms, do: label_name

    %Phail.Query{labels: labels, text: text}
  end

  defp parser, do: sep_by(search_term(), spaces())

  defp search_term(previous \\ nil) do
    previous
    |> either(label(), text_term())
  end

  defp text_term(previous \\ nil) do
    previous
    |> word
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
end
