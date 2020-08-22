defmodule Phail.Query do
  defstruct labels: [], text: ""

  def parse_query(query_string) do
    parts = String.split(query_string, ~r/ +/)
    parts = Enum.map(parts, &parse_term/1)
    text_terms = for {:text, text} <- parts, do: text
    text = Enum.join(text_terms, " & ")
    labels = for {:label, label_name} <- parts, do: label_name

    %Phail.Query{labels: labels, text: text}
  end

  defp parse_term(term) do
    case String.split(term, ":", parts: 2) do
      [text] -> {:text, text}
      ["label", label_name] -> {:label, String.downcase(label_name)}
    end
  end
end
