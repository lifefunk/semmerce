defmodule Core.Aggregate do
  alias Core.Structure
  alias Core.Event, as: CoreEvent

  @error_missing_entity {:error, {:aggregate, "missing aggregate entity"}}
  @error_unknown_aggregate_structure {:error, {:aggregate, "unknown aggregate structure"}}
  @error_invalid_aggregate_type {:error, {:aggregate, "invalid aggregate type"}}

  @doc """
  Used to extract a third element (index: 2) from given aggregate tuple parameter. If the given
  parameter not follow the structure like doesn't have any index of 2, it will return an error
  """
  @spec aggregate(agg :: Structure.aggregate()) :: Structure.results()
  def aggregate(agg) when is_tuple(agg) do
    try do
      {:ok, elem(agg, 2)}
    rescue
      e in ArgumentError -> {:error, {:exception, e.message}}
    end
  end

  @spec name(agg :: Structure.aggregate()) :: Structure.results()
  def name(agg) when is_tuple(agg) do
    try do
      {:ok, elem(agg, 1)}
    rescue
      e in ArgumentError -> {:error, {:exception, e.message}}
    end
  end

  @doc """
  Used for custom aggregate structure, let's the caller decide how to extract the object
  The value given to the callback is a value of element with index 2 then give the results
  to the caller's callback

  When we need to extract entity from the real aggregate object. The given aggregate tuple
  must have an element with index 2 and the value is a struct which has an :entity field, if the structure
  is different, return an error unknown structure, on this case we should give nil value for the callback
  parameter
  """
  @spec entity(agg :: Structure.aggregate(), callback :: (Structure.results() -> Structure.results())) :: Structure.results()
  def entity(agg, callback) when is_tuple(agg) and is_function(callback) do
    callback.(agg |> aggregate)
  end

  @spec entity(agg :: Structure.aggregate(), callback :: atom()) :: Structure.results()
  def entity(agg, callback) when is_tuple(agg) and is_nil(callback) do
    agg_object =
      agg
      |> aggregate

    case agg_object do
      {:ok, agg_struct} when is_struct(agg_struct) ->
        if Map.has_key?(agg_struct, :entity) do
          Map.get(agg_struct, :entity)
        else
          @error_missing_entity
        end
      {:ok, _} ->
        @error_unknown_aggregate_structure
      {:error, {error_type, error_message}} ->
        {:error, {error_type, error_message}}
    end
  end

  def entity(_, _), do: @error_invalid_aggregate_type

  @doc """
  Update an aggregate object values. It must follow this format:

  ```elixir
    {:aggregate, aggregate_name, aggregate_payload}
  ```

  And for the `aggregate_payload` it must follow this format:

  ```elixir
    %Aggregate{entity: struct(), events: list(Structure.event())}
  ```

  The `aggregate_name` must follow the structure types, an `atom()` or `binary()`.
  This function will rebuild the aggregate tuple structure, with same `aggregate_name`
  and new `aggregate_payload` updated with given entity and event
  """
  @spec update(agg :: Structure.aggregate(), entity :: struct(), event :: Structure.event()) :: Structure.results()
  def update(agg, entity, event) when is_tuple(agg) and is_struct(entity) and is_tuple(event) do
    out_agg = agg |> aggregate
    case out_agg do
      {:ok, agg_object} when is_struct(agg_object) ->
        if !Map.has_key?(agg_object, :entity) do
          @error_invalid_aggregate_type
        else
          out =
            %{agg_object | entity: entity, events: CoreEvent.add_event(agg_object.events, event)}

          aggregate_name = agg |> name
          case aggregate_name do
            {:ok, name} when is_atom(name) or is_binary(name) ->
              {:ok, {:aggregate, name, out}}
            {:ok, _} ->
              @error_invalid_aggregate_type
            {:error, {error_type, error_message}} ->
              {:error, {error_type, error_message}}
          end
        end
      _ ->
        out_agg
    end
  end
  def update(_, _, _), do: @error_invalid_aggregate_type
end
