defmodule Product.Core.Aggregate do
  @moduledoc """
  We need to create this module to proceed all business logic from our Entity
  including for it's event management. Especially for event management, I think it's better
  to manage all events from the aggregate instead of from Entity. I think it's better to make
  our Entity as clean as possible and focus for it's business logic, all the event changes will
  produced via Aggregate
  """
  alias Core.Structure, as: CoreStructure
  alias Core.Event, as: CoreEvent
  alias Product.Core.Aggregate
  alias Product.Core.Aggregate.Event, as: ProductEvent
  alias Product.Core.Structure.Entity, as: ProductEntity
  alias Product.Category.Core.Structure, as: CategoryStructure

  @enforce_keys [:entity, :events]
  defstruct [:entity, :events]

  @typedoc """
  This is main aggregate map structure, any operation inside an aggregate should used
  this structure
  """
  @type t :: %__MODULE__{
    entity: ProductEntity.t() | nil,
    events: list(CoreStructure.event()),
  }

  @aggregate_name :product
  @error_invalid_product_type {:error, {:product_type, "invalid product type"}}

  defmodule Event do
    @moduledoc """
    Event used to describe all possible product's events for state changes
    """
    @error_invalid_product_type {:error, {:product_type, "invalid given product entity type"}}

    @doc """
    product_created used when a new product successfully created and saved in database
    """
    @spec product_created(product :: ProductEntity.t()) :: {:ok, CoreStructure.event()}
    def product_created(product) when is_struct(product), do: {:ok, {:event, :product_created, product}}

    @spec product_created(any()) :: CoreStructure.error()
    def product_created(_), do: @error_invalid_product_type

    @doc """
    product_modified used when a new product successfully modified
    """
    @spec product_modified(product :: ProductEntity.t()) :: {:ok, CoreStructure.event()}
    def product_modified(product) when is_struct(product), do: {:ok, {:event, :product_modified, product}}
    def product_modified(_), do: @error_invalid_product_type

    @doc """
    product_deleted used when a product deleted from system
    """
    @spec product_deleted(product :: ProductEntity.t()) :: {:ok, CoreStructure.event()}
    def product_deleted(product) when is_struct(product), do: {:ok, {:event, :product_deleted, product}}

    @spec product_deleted(any()) :: CoreStructure.error()
    def product_deleted(_), do: @error_invalid_product_type
  end

  @doc """
  Generate new aggregate data structure from given product's entity
  For the first initialization, all events should be an empty list
  """
  @spec new(product :: ProductEntity.t()) :: CoreStructure.aggregate()
  def new(product) do
    {:aggregate, @aggregate_name, %Aggregate{
      entity: product,
      events: []
    }}
  end

  @doc """
  create_new used to generate new entity of product and also set product's event product_created
  """
  @spec create_new(agg :: t(), product :: ProductEntity.new_product(), category :: CategoryStructure.Entity.t()) :: {:ok, t()} | CoreStructure.error()
  def create_new(agg, product, category) when is_struct(agg) and is_map(product) and is_struct(category) do
    with {:ok, entity} <- ProductEntity.new(product, category),
         {:ok, event} <- ProductEvent.product_created(entity)
    do
      update_aggregate(agg, entity, event)
    else
      err -> err
    end
  end
  def create_new(_ , _, _), do: @error_invalid_product_type

  @doc """
  change_category used to update given product's entity, changing it's category
  """
  @spec change_category(agg :: t(), product :: ProductEntity.t(), category :: CategoryStructure.Entity.t()) :: {:ok, t()} | CoreStructure.error()
  def change_category(agg, product, category) when is_struct(agg) and is_struct(product) and is_struct(category) do
    with {:ok, entity} <- ProductEntity.change_category(product, category),
         {:ok, event} <- ProductEvent.product_modified(entity)
    do
      update_aggregate(agg, entity, event)
    else
      err -> err
    end
  end
  def change_category(_, _, _), do: @error_invalid_product_type

  @doc """
  change_name used to update product's name
  """
  @spec change_name(agg :: t(), product :: ProductEntity.t(), name :: String.t()) :: {:ok, t()} | CoreStructure.error()
  def change_name(agg, product, name) when is_struct(agg) and is_struct(product) and is_binary(name) do
    with {:ok, entity} <- ProductEntity.change_name(product, name),
         {:ok, event} <- ProductEvent.product_modified(entity)
    do
      update_aggregate(agg, entity, event)
    else
      err -> err
    end
  end
  def change_name(_, _, _), do: @error_invalid_product_type

  @doc """
  change_desc used to update product's description
  """
  @spec change_desc(agg :: t(), product :: ProductEntity.t(), desc :: String.t()) :: {:ok, t()} | CoreStructure.error()
  def change_desc(agg, product, desc) when is_struct(agg) and is_struct(product) and is_binary(desc) do
    with {:ok, entity} <- ProductEntity.change_desc(product, desc),
         {:ok, event} <- ProductEvent.product_modified(entity)
    do
      update_aggregate(agg, entity, event)
    else
      err -> err
    end
  end
  def change_desc(_, _, _), do: @error_invalid_product_type

  @doc """
  change_price used to update product's price
  """
  @spec change_price(agg :: t(), product :: ProductEntity.t(), price :: non_neg_integer()) :: {:ok, t()} | CoreStructure.error()
  def change_price(agg, product, price) when is_struct(agg) and is_struct(product) and is_integer(price) do
    with {:ok, entity} <- ProductEntity.change_price(product, price),
         {:ok, event} <- ProductEvent.product_modified(entity)
    do
      update_aggregate(agg, entity, event)
    else
      err -> err
    end
  end
  def change_price(_, _, _), do: @error_invalid_product_type

  @doc """
  remove_product is not doing anything, it's only for generate product's event
  """
  @spec remove_product(agg :: t(), product :: ProductEntity.t()) :: {:ok, t()} | CoreStructure.error()
  def remove_product(agg, product) when is_struct(agg) and is_struct(product) do
    out = ProductEvent.product_deleted(product)
    case out do
      {:ok, event} ->
        update_aggregate(agg, product, event)
      {:error, _error} ->
        out
    end
  end
  def remove_product(_, _), do: @error_invalid_product_type

  defp update_aggregate(agg, entity, event) when is_struct(agg) and is_struct(entity) and is_tuple(event) do
    out =
      %{agg | entity: entity, events: CoreEvent.add_event(agg.events, event)}

    {:ok, out}
  end
  defp update_aggregate(_, _, _), do: @error_invalid_product_type
end
