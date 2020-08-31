defmodule Phail.QueryTest do
  use ExUnit.Case
  import Phail.Query
  alias Phail.Query

  describe "parse/1" do
    test "parse_simple_label" do
      assert parse("label:Inbox") == %Query{labels: ["Inbox"]}
    end

    test "parse_label_with_space" do
      assert parse("label:\"Category Personal\"") == %Query{labels: ["Category Personal"]}
    end

    test "parse_labels" do
      assert parse("label:a label:b") == %Query{labels: ["a", "b"]}
    end

    test "parse_words" do
      assert parse("word1 word2 two-word") == %Query{text_terms: ["word1", "word2", "two-word"]}
    end

    test "parse_extra_ws" do
      assert parse("   hello     world  ") == %Query{text_terms: ["hello", "world"]}
    end
  end

  describe "format/1" do
    test "format_texts" do
      assert format(%Query{text_terms: ["three", "whole", "words"]}) == "three whole words"
    end

    test "format_labels" do
      assert format(%Query{labels: ["Inbox"]}) == "label:Inbox"
    end
  end

  describe "round_trip_encode_decode" do
    test "simple" do
      sample = %Query{labels: ["Inbox"]}
      assert sample == encode_decode(sample)
    end

    test "space" do
      sample = %Query{labels: ["Category Personal"]}
      assert sample == encode_decode(sample)
    end

    test "texts" do
      sample = %Query{text_terms: ["word", "word2", "Hello"]}
      assert sample == encode_decode(sample)
    end
  end

  defp encode_decode(x) do
    parse(format(x))
  end
end
