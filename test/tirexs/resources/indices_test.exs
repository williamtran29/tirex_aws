defmodule Tirexs.Resources.IndicesTest do
  use ExUnit.Case

  alias Tirexs.Resources.Indices


  @resources [
    "_refresh", "_flush", "_forcemerge", "_upgrade", "_alias", "_aliases",
    "_stats", "_segments", "_recovery", "_shard_stores", "_close", "_open",
    "_analyze", "_warmer", "_template", "_settings",
    "_mapping"
  ]

  test ~S/functions like a '_refresh()'/ do
    Enum.each @resources, fn(resource) ->
      # actual = Indices._refresh()
      actual = Kernel.apply(Indices, String.to_atom(resource), [])
      assert actual == "#{resource}"
    end
  end

  test ~S/functions like a '_refresh({ [local: true] })'/ do
    Enum.each @resources, fn(resource) ->
      # actual = Indices._refresh({ [local: true] })
      actual = Kernel.apply(Indices, String.to_atom(resource), [{ [local: true] }])
      assert actual == "#{resource}?local=true"
    end
  end

  test ~S/functions like a '_refresh({ %{local: true} })'/ do
    Enum.each @resources, fn(resource) ->
      # actual = Indices._refresh({ %{local: true} })
      actual = Kernel.apply(Indices, String.to_atom(resource), [{ %{local: true} }])
      assert actual == "#{resource}?local=true"
    end
  end

  test ~S/functions like a '_refresh("bear_test")'/ do
    Enum.each @resources, fn(resource) ->
      # actual = Indices._refresh("bear_test")
      actual = Kernel.apply(Indices, String.to_atom(resource), ["bear_test"])
      assert actual == "bear_test/#{resource}"
    end
  end

  test ~S/functions like a '_refresh("bear_test", { [local: false] })'/ do
    Enum.each @resources, fn(resource) ->
      # actual = Indices._refresh("bear_test", { [local: false] })
      actual = Kernel.apply(Indices, String.to_atom(resource), ["bear_test", { [local: false] }])
      assert actual == "bear_test/#{resource}?local=false"
    end
  end

  test ~S/functions like a '_refresh(["bear_test", "duck_test"])'/ do
    Enum.each @resources, fn(resource) ->
      # actual = Indices._refresh(["bear_test", "duck_test"])
      actual = Kernel.apply(Indices, String.to_atom(resource), [["bear_test", "duck_test"]])
      assert actual == "bear_test,duck_test/#{resource}"
    end
  end

  test ~S/functions like a '_refresh(["bear_test", "duck_test"], { [local: false] })'/ do
    Enum.each @resources, fn(resource) ->
      # actual = Indices._refresh(["bear_test", "duck_test"], { [local: false] })
      actual = Kernel.apply(Indices, String.to_atom(resource), [["bear_test", "duck_test"], { [local: false] }])
      assert actual == "bear_test,duck_test/#{resource}?local=false"
    end
  end

  test ~S/functions like a '_refresh("bear_test", "2015")'/ do
    Enum.each @resources, fn(resource) ->
      # actual = Indices._refresh("bear_test", "2015")
      actual = Kernel.apply(Indices, String.to_atom(resource), ["bear_test", "2015"])
      assert actual == "bear_test/#{resource}/2015"
    end
  end

  test ~S/functions like a '_refresh(["bear_test", "duck_test"], "2015")'/ do
    Enum.each @resources, fn(resource) ->
      # actual = Indices._refresh(["bear_test", "duck_test"], "2015")
      actual = Kernel.apply(Indices, String.to_atom(resource), [["bear_test", "duck_test"], "2015"])
      assert actual == "bear_test,duck_test/#{resource}/2015"
    end
  end

  test ~S/functions like a '_refresh("bear_test", "2015", { [local: true] })'/ do
    Enum.each @resources, fn(resource) ->
      # actual = Indices._refresh("bear_test", "2015", { [local: true] })
      actual = Kernel.apply(Indices, String.to_atom(resource), ["bear_test", "2015", { [local: true] }])
      assert actual == "bear_test/#{resource}/2015?local=true"
    end
  end

  test ~S/functions like a '_refresh("bear_test", "2015", { %{local: true} })'/ do
    Enum.each @resources, fn(resource) ->
      # actual = Indices._refresh("bear_test", "2015", { %{local: true} })
      actual = Kernel.apply(Indices, String.to_atom(resource), ["bear_test", "2015", { %{local: true} }])
      assert actual == "bear_test/#{resource}/2015?local=true"
    end
  end

  test ~S/functions like a '_cache_clear()'/ do
    actual = Indices._cache_clear()
    assert actual == "_cache/clear"
  end

  test ~S/functions like a '_all_mapping()'/ do
    actual = Indices._all_mapping()
    assert actual == "_all/_mapping"
  end

  test ~S/functions like a '_cache_clear(["bear_test", "duck_test"])'/ do
    actual = Indices._cache_clear(["bear_test", "duck_test"])
    assert actual == "bear_test,duck_test/_cache/clear"
  end

  test ~S/functions like a '_field_mapping(["bear_test", "duck_test"])'/ do
    actual = Indices._field_mapping(["bear_test", "duck_test"])
    assert actual == "bear_test,duck_test/_mapping/field"
  end

  test ~S/functions like a '_field_mapping(["bear_test", "duck_test"], "message")'/ do
    actual = Indices._field_mapping(["bear_test", "duck_test"], "message")
    assert actual == "bear_test,duck_test/_mapping/field/message"
  end

  test ~S/functions like a '_field_mapping("_all", "tw*", "*.id")'/ do
    actual = Indices._field_mapping("_all", "tw*", "*.id")
    assert actual == "_all/_mapping/tw*/field/*.id"
  end

  @tag skip: "pending"
  test ~S/functions like a '_mapping("bear_test", "bear_type")'/ do
    actual = Indices._mapping("bear_test", "bear_type")
    assert actual == "bear_test/bear_type/_mapping"
  end
end
