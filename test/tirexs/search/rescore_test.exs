Code.require_file "../../../test_helper.exs", __ENV__.file

defmodule Tirexs.Search.RescoreTest do
  use ExUnit.Case

  import Tirexs.Search.Rescore


  test :rescore do
    rescore = rescore do
      query do
        rescore_query do
          match "field1", "the quick brown", [type: "phrase", slop: 2]
        end
      end
    end

    expected = [rescore: [query: [rescore_query: [match: [field1: [query: "the quick brown", type: "phrase", slop: 2]]]]]]
    assert rescore == expected
  end

  test :rescore_with_params do
    rescore = rescore [window_size: 50] do
      query [query_weight: 0.7, rescore_query_weight: 1.2] do
        rescore_query do
          match "field1", "the quick brown", [type: "phrase", slop: 2]
        end
      end
    end

    expected = [rescore: [query: [rescore_query: [match: [field1: [query: "the quick brown", type: "phrase", slop: 2]]], query_weight: 0.7, rescore_query_weight: 1.2], window_size: 50]]
    assert rescore == expected
  end
end
