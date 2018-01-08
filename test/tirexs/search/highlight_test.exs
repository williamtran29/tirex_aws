Code.require_file "../../../test_helper.exs", __ENV__.file

defmodule Tirexs.Search.HighlightTest do
  use ExUnit.Case

  import Tirexs.Search


  test :highlight do
    highlight = highlight do
      [ number_of_fragments: 3,
        fragment_size: 150,
        tag_schema: "styled",
        fields: [
            _all: [pre_tags: ["<em>"], post_tags: ["</em>"]],
            "bio.title": [number_of_fragments: 0],
            "bio.author": [number_of_fragments: 0],
            "bio.content": [number_of_fragments: 5, order: "score" ]
          ]
      ]
    end

    expected = [highlight: [number_of_fragments: 3, fragment_size: 150, tag_schema: "styled", fields: [_all: [pre_tags: ["<em>"], post_tags: ["</em>"]], "bio.title": [number_of_fragments: 0], "bio.author": [number_of_fragments: 0], "bio.content": [number_of_fragments: 5, order: "score"]]]]
    assert highlight ==  expected
  end
end
