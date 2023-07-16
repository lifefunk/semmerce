defmodule Product.Category.Core.Aggregate do
  alias Core.Structure, as: CoreStructure
  alias Core.Event, as: CoreEvent
  alias Product.Category.Core.Aggregate
  alias Product.Category.Core.Structure.Entity, as: CategoryEntity
  alias Product.Category.Core.Aggregate.Event, as: CategoryEvent

  @enforce_keys [:entity, :events]
  defstruct [:entity, :events]

  @typedoc """
  This is main aggregate map structure, any operation inside an aggregate should used
  this structure
  """
  @type t :: %__MODULE__{
    entity: CategoryEntity.t(),
    events: list(CoreStructure.event()),
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

  @doc """
  Create new category for it's entity and it's event
  """
  @spec create_new(agg :: t(), category :: CategoryEntity.new_category()) :: {:ok, t()} | CoreStructure.error()
  def create_new(agg, category) when is_struct(agg) and is_map(category) do
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
  @spec change_name(agg :: t(), category :: CategoryEntity.t(), name :: String.t()) :: {:ok, t()} | CoreStructure.error()
  def change_name(agg, category, name) when is_struct(category) and is_binary(name) do
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
  @spec change_desc(agg :: t(), category :: CategoryEntity.t(), desc :: String.t()) :: {:ok, t()} | CoreStructure.error()
  def change_desc(agg, category, desc) when is_struct(agg) and is_struct(category) and is_binary(desc) do
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
  @spec remove_category(agg :: t(), category :: CategoryEntity.t()) :: {:ok, t()}
  def remove_category(agg, category) when is_struct(agg) and is_struct(category) do
    out = CategoryEvent.category_deleted(category)
    case out do
      {:ok, event} ->
        update_aggregate(agg, category, event)
      {:error, _error} ->
        out
    end
  end
  def remove_category(_, _), do: @error_invalid_category_type

  defp update_aggregate(agg, entity, event) when is_struct(agg) and is_struct(entity) and is_tuple(event) do
    out =
      %{agg | entity: entity, events: CoreEvent.add_event(agg.events, event)}

    {:ok, out}
  end
end
