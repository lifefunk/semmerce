defmodule Product.Category.Core.Aggregate do
  alias Core.Structure, as: CoreStructure
  alias Core.Event, as: CoreEvent
  alias Product.Category.Core.Aggregate
  alias Product.Category.Core.Structure.Entity, as: CategoryEntity
  alias Product.Category.Core.Aggregate.Event, as: CategoryEvent

  defstruct [:entity, :events]

  @typedoc """
  This is main aggregate map structure, any operation inside an aggregate should used
  this structure
  """
  @type t :: %__MODULE__{
    entity: CategoryEntity.t() | nil,
    events: list(CoreStructure.event()) | list(),
  }

  @aggregate_name :category
  @error_invalid_category_type {:error, {:category_type, "invalid category type"}}

  defmodule Event do
    @moduledoc """
    Describe all possible category events
    """
    @error_invalid_category_type {:error, "invalid given category entity type"}

    @doc """
    Used when category successfully created
    """
    @spec category_created(category :: CategoryEntity.t()) :: {:ok, CoreStructure.event()}
    def category_created(category) when is_struct(category), do: {:ok, {:event, :category_created, category}}

    @spec category_created(any()) :: CoreStructure.error()
    def category_created(_), do: @error_invalid_category_type

    @doc """
    Used when category successfully edited
    """
    @spec category_edited(category :: CategoryEntity.t()) :: {:ok, CoreStructure.event()}
    def category_edited(category) when is_struct(category), do: {:ok, {:event, :category_edited, category}}

    @spec category_edited(any()) :: CoreStructure.error()
    def category_edited(_), do: {:error, @error_invalid_category_type}

    @doc """
    Used when category successfully deleted
    """
    @spec category_deleted(category :: CategoryEntity.t()) :: {:ok, CoreStructure.event()}
    def category_deleted(category) when is_struct(category), do: {:ok, {:event, :category_deleted, category}}

    @spec category_deleted(any()) :: CoreStructure.error()
    def category_deleted(_), do: {:error, @error_invalid_category_type}
  end

  @doc """
  Create new category aggregate structure
  """
  @spec new(category :: CategoryEntity.t()) :: CoreStructure.aggregate()
  def new(category) do
    {:aggregate, @aggregate_name, %Aggregate{
      entity: category,
      events: []
    }}
  end

  @spec new() :: CoreStructure.aggregate()
  def new() do
    {:aggregate, @aggregate_name, %Aggregate{}}
  end

  @doc """
  Create new category for it's entity and it's event
  """
  @spec create_new(
    agg :: CoreStructure.aggregate(),
    category :: CategoryEntity.new_category()) :: {:ok, CoreStructure.aggregate()} | CoreStructure.error()
  def create_new(agg, category)
      when is_tuple(agg)
      and is_map(category) do

    with {:ok, entity} <- CategoryEntity.new(category),
         {:ok, event} <- CategoryEvent.category_created(entity)
    do
      update_aggregate(agg, entity, event)
    else
      err -> err
    end

  end
  def create_new(_, _), do: @error_invalid_category_type

  @doc """
  Change category name
  """
  @spec change_name(
    agg :: CoreStructure.aggregate(),
    category :: CategoryEntity.t(),
    name :: String.t()) :: {:ok, CoreStructure.aggregate()} | CoreStructure.error()
  def change_name(agg, category, name)
      when is_tuple(agg)
      and is_struct(category)
      and is_binary(name) do

    with {:ok, entity} <- CategoryEntity.change_name(category, name),
         {:ok, event} <- CategoryEvent.category_edited(entity)
    do
      update_aggregate(agg, entity, event)
    else
      err -> err
    end

  end
  def change_name(_, _, _), do: @error_invalid_category_type

  @doc """
  Change category description
  """
  @spec change_desc(
    agg :: CoreStructure.aggregate(),
    category :: CategoryEntity.t(),
    desc :: String.t()) :: {:ok, CoreStructure.aggregate()} | CoreStructure.error()
  def change_desc(agg, category, desc)
      when is_tuple(agg)
      and is_struct(category)
      and is_binary(desc) do

    with {:ok, entity} <- CategoryEntity.change_desc(category, desc),
         {:ok, event} <- CategoryEvent.category_edited(entity)
    do
      update_aggregate(agg, entity, event)
    else
      err -> err
    end

  end
  def change_desc(_, _, _), do: @error_invalid_category_type

  @doc """
  Remove category from system. It is just create an event to used by other caller
  """
  @spec remove_category(
    agg :: CoreStructure.aggregate(),
    category :: CategoryEntity.t()) :: {:ok, CoreStructure.aggregate()} | CoreStructure.error()
  def remove_category(agg, category)
      when is_tuple(agg)
      and is_struct(category) do

    out = CategoryEvent.category_deleted(category)
    case out do
      {:ok, event} ->
        update_aggregate(agg, category, event)
      {:error, _error} ->
        out
    end

  end
  def remove_category(_, _), do: @error_invalid_category_type

  @spec aggregate(agg :: CoreStructure.aggregate()) :: {:ok, t()} | CoreStructure.error()
  def aggregate(agg) when is_tuple(agg) do
    try do
      elem(agg, 2)
    rescue
      e in ArgumentError -> {:error, {:exception, e.message}}
    end
  end

  @spec entity(agg :: t()) :: CategoryEntity.t()
  def entity(agg) when is_struct(agg), do: agg.entity

  @spec update_aggregate(agg :: CoreStructure.aggregate(), entity :: CategoryEntity.t(), event :: CoreStructure.event()) :: {:ok, CoreStructure.aggregate()} | CoreStructure.error()
  defp update_aggregate(agg, entity, event) when is_tuple(agg) and is_struct(entity) and is_tuple(event) do
    out = aggregate(agg)
    case out do
      {:ok, category} ->
        out =
          %{category | entity: entity, events: CoreEvent.add_event(category.events, event)}
        {:ok, {:aggregate, @aggregate_name, out}}
      _ ->
        out
    end
  end
end
