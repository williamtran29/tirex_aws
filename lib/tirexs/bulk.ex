defmodule Tirexs.Bulk do
  @moduledoc """
  The Bulk API makes it possible to perform many index/delete operations in
  single call.

  This module provides DSL for building Bulk API `payload` which is ready to use
  over `Tirexs.Resources.bump/1` or `Tirexs.HTTP.post/2` conveniences.

  The `Tirexs.Resources.bump/1` expects `payload` as a set of JSON documents joined
  together by newline (\n) characters.

      payload = ~S'''
      { "index": { "_index": "website", "_type": "blog", "_id": "1" }}
      { "title": "My second blog post" }
      '''
      # { :ok, 200, r } = HTTP.post("/_bulk", payload)
      # { :ok, 200, r } = Resources.bump(payload)._bulk({ [refresh: true] })
      { :ok, 200, r } = Resources.bump(payload)._bulk()

  A `bulk` macro helps create a single `payload` from parts (`action`, `metadata`, `request body`)
  where you Don't need to Repeat Yourself ;).

  For instance:

      payload = bulk([ index: "website", type: "blog" ]) do
        index [
          [id: 1, title: "My first blog post"],
          [id: 2, title: "My second blog post"]
        ]
        update [
          [
            doc: [id: 1, _retry_on_conflict: 3, title: "[updated] My first blog post"],
            fields: ["_source"],
          ],
          [
            doc: [id: 2, _retry_on_conflict: 3, title: "[updated] My second blog post"],
            doc_as_upsert: true,
          ]
        ]
      end

  Find out more details and examples in the `bulk/2` macro doc.

  """

  import Tirexs.DSL.Logic


  @doc """
  Builds `payload` from given block and returns the Bulk API JSON structure.

  The Bulk request body has the following `action`, `metadata` and `request body`
  parts.

  The bulk to particular `_index/_type`:

      payload = bulk do
        index [
          [id: 1, title: "My second blog post"]
          # ...
        ]
      end
      Tirexs.bump(payload)._bulk("website/blog", { [refresh: true] })

  The same `metadata` for every document:

      payload = bulk([ index: "website", type: "blog" ]) do
        index [
          [id: 1, title: "My second blog post"]
          # ...
        ]
      end
      Tirexs.bump(payload)._bulk()

  Index specific insertion:

      payload = bulk do
        index [ index: "website.a", type: "blog" ], [
          [title: "My blog post"]
          # ...
        ]
        index [ index: "website.b", type: "blog" ], [
          [title: "My blog post"]
          # ...
        ]
      end
      Tirexs.bump(payload)._bulk()

  The `action` could be `index`, `create`, `update` and `delete`.

  Update example:

      bulk do
        update [ index: "website", type: "blog"], [
          [
            doc: [id: 1, _retry_on_conflict: 3, title: "[updated] My first blog post"],
            fields: ["_source"],
          ],
          [
            doc: [id: 2, _retry_on_conflict: 3, title: "[updated] My second blog post"],
            doc_as_upsert: true,
          ]
        ]
      end

  Delete example:

      bulk do
        delete [ index: "website.b", type: "blog" ], [
          [id: "1"]
          # ...
        ]
      end

  """
  defmacro bulk(metadata \\ [], [do: block]) do
    quote do: payload_as_string(unquote(metadata), [do: unquote(block)])
  end

  @doc false
  defmacro payload_as_string(metadata \\ [], [do: block]) do
    quote do
      payload = payload_as_list(unquote(metadata), [do: unquote(block)])
      payload = Enum.map(payload, fn(item) -> Tirexs.HTTP.encode(item) end)
      Enum.join(payload, "\n") <> "\n"
    end
  end

  @doc false
  defmacro payload_as_list(metadata \\ [], [do: block]) do
    payload = extract_block(block)
    payload = case payload do
      {_,_,_} -> [payload]
      _       -> payload
    end
    quote do
      {payload, metadata} = {unquote(payload), unquote(metadata)}
      payload = case payload do
        [{_key, _value}|_t] -> payload
        _ -> Enum.reduce(payload, [], fn(list, acc) -> acc ++ list end)
      end
      payload = if Enum.empty?(metadata) do
        payload
      else
        Enum.map(payload, fn(item) ->
          action = Keyword.take(item, [:index, :create, :delete, :update])
          cond do
            not Enum.empty?(action) ->
              [{action, meta}|_t] = action
              meta                = Keyword.merge(Tirexs.Bulk.undescored_keys(metadata), meta)
              Keyword.merge(item, [{action, meta}])
            true ->
              item
          end
        end)
      end
    end
  end


  @doc "Prepares `request_body` and `index` action all together."
  def index(request_body) do
    Enum.reduce(request_body, [], __reduce(:index))
  end
  def index(metadata, request_body) do
    Enum.map(index(request_body), __map(:index, metadata))
  end

  @doc "Prepares `request_body` and `create` action all together."
  def create(request_body) do
    Enum.reduce(request_body, [], __reduce(:create))
  end
  def create(metadata, request_body) do
    Enum.map(create(request_body), __map(:create, metadata))
  end

  @doc "Prepares `request_body` and `update` action all together."
  def update(request_body) do
    Enum.reduce(request_body, [], __reduce(:update))
  end
  def update(metadata, request_body) do
    Enum.map(update(request_body), __map(:update, metadata))
  end

  @doc "Prepares `request_body` and `delete` action all together."
  def delete(request_body) do
    Enum.map(request_body, fn(doc) -> [delete: take_id(doc)] end)
  end
  def delete(metadata, request_body) do
    Enum.map(delete(request_body), __map(:delete, metadata))
  end

  @doc false
  def undescored_keys(list) do
    Enum.map(list, fn({k,v}) -> {:"_#{k}", v} end)
  end

  @doc false
  def get_id_from_document(document) do
    document[:id] || document[:_id]
  end

  @doc false
  def get_type_from_document(document) do
    document[:_type] || document[:type] || "document"
  end


  defp take_id(doc) do
    if id = get_id_from_document(doc), do: [ _id: id ], else: []
  end

  defp drop_id(doc) do
    Keyword.drop(doc, [:id])
  end

  @undescored [:_parent, :_percolate, :_retry_on_conflict, :_routing, :_timestamp, :_ttl, :_version, :_version_type]

  defp drop_undescored(doc) do
    Keyword.drop(doc, @undescored)
  end

  defp take_header(doc) do
    Keyword.take(doc, @undescored)
  end

  defp take_meta(action, doc) when action == :update do
    Keyword.take(doc, [:doc, :upsert, :doc_as_upsert, :script, :params, :lang, :fields])
  end

  defp __reduce(action) when action == :index or action == :create do
    fn(doc, acc) ->
      header = [{action, (take_id(doc) ++ take_header(doc))}]
      meta   = drop_id(doc) |> drop_undescored()
      acc ++ [header] ++ [meta]
    end
  end

  defp __reduce(action) when action == :update do
    fn(doc, acc) ->
      header = [{action, (take_id(doc[:doc]) ++ take_header(doc[:doc]))}]
      meta   = take_meta(:update, doc)
      meta   = put_in(meta, [:doc], (drop_id(meta[:doc]) |> drop_undescored()))
      acc ++ [header] ++ [meta]
    end
  end

  defp __map(action, metadata) do
    fn(header) ->
      if Keyword.has_key?(header, action) do
        [{action, Keyword.merge(undescored_keys(metadata), header[action])}]
      else
        header
      end
    end
  end
end
