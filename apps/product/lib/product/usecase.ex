defmodule Product.Usecase do
  @moduledoc """
  Product's activities will be:

  * - get_products
  * - get_products_by_category_id
  * - get_product_by_id
  * - create_new
  * - change_product_category
  * - change_product_name
  * - change_product_desc
  * - change_product_price
  * - delete_product
  """

  alias Core.Structure, as: CoreType
  alias Core.Structure.Function.Builder.Dependency, as: FunctionDep
  alias Product.Core.Aggregate, as: ProductAggregate
  alias Product.Core.Structure.Entity, as: ProductEntity
  alias Product.Category.Core.Aggregate, as: CategoryAggregate

  @error_nil_value {:error, {:value, "has a nil value"}}
  @error_unknown_exception {:error, {:exception, "unknown exception"}}

  @spec new(repoProduct :: module(), repoCategory :: module(), opts :: keyword()) :: FunctionDep.t()
  def new(repoProduct, repoCategory, opts \\ []) when is_atom(repoProduct) and is_atom(repoCategory) do
    %FunctionDep{
      deps: %{
        :product => repoProduct,
        :category => repoCategory
      },
      options: opts
    }
  end

  @spec get_products(deps :: FunctionDep.t()) :: {:ok, list(ProductEntity.t())} | CoreType.error()
  def get_products(deps) when is_struct(deps) do
    with repo <- Map.get(deps, :deps),
         {:ok, products} <- repo.product.get_products()
    do
      get_product_entities(products)
    else
      nil -> @error_nil_value
      {:error, errors} -> {:error, errors}
    end
  end

  @spec get_products_by_category_id(deps :: FunctionDep.t(), category_id :: String.t()) :: {:ok, list(ProductEntity.t())} | CoreType.error()
  def get_products_by_category_id(deps, category_id) when is_struct(deps) and is_binary(category_id) do
    with repo <- Map.get(deps, :deps),
         {:ok, products} <- repo.product.get_products_by_category_id(category_id)
    do
      get_product_entities(products)
    else
      nil -> @error_nil_value
      {:error, errors} -> {:error, errors}
    end
  end

  @spec get_product_by_id(dpes :: FunctionDep.t(), product_id :: String.t()) :: {:ok, ProductEntity.t()} | CoreType.error()
  def get_product_by_id(deps, product_id) when is_struct(deps) and is_binary(product_id) do
    with repo <- Map.get(deps, :deps),
         {:ok, aggregate} <- repo.product.get_product_by_id(product_id)
    do
      try do
        # extract product's entity from current product's aggregate
        {:ok, aggregate |> extract_entity_from_aggregate!}
      rescue
        e in ArgumentError -> {:error, {:exception, e.message}}
        _ -> @error_unknown_exception
      end
    else
      nil -> @error_nil_value
      {:error, errors} -> {:error, errors}
    end
  end

  @spec create_product(deps :: FunctionDep.t(), product :: ProductEntity.new_product(), category_id :: String.t()) :: {:ok, ProductEntity.t()} | CoreType.error()
  def create_product(deps, product, category_id)
                    when is_struct(deps)
                    and is_map(product)
                    and is_binary(category_id) do

    with repo <- Map.get(deps, :deps),
         {:ok, category_aggregate} <- repo.category.get_category_by_id(category_id) |> CategoryAggregate.aggregate,
         category <- category_aggregate |> CategoryAggregate.entity,
         {:ok, product_created} <- ProductAggregate.new |> ProductAggregate.create_new(product, category),
         {:ok, product_saved} <- product_created |> repo.product.save,
         {:ok, product_saved_agg} <- product_saved |> ProductAggregate.aggregate
    do
      {:ok, product_saved_agg |> ProductAggregate.entity}
    else
      nil -> @error_nil_value
      {:error, {error_type, error_msg}} -> {:error, {error_type, error_msg}}
      {:error, error_msg} -> {:error, {:internal, error_msg}}
    end

  end

  @spec get_product_entities(product_aggregates :: list(CoreType.aggregate())) :: {:ok, list(ProductEntity.t())} | CoreType.error()
  defp get_product_entities(product_aggregates) do
    if length(product_aggregates) < 1 do
      {:ok, []}
    else
      # need to guard our operation due to `elem/2` has possibility
      # to raise an Exception
      try do
        # extract product's entity from current product's aggregate
        {:ok, Enum.map(product_aggregates, fn aggregate ->
          aggregate
          |> extract_entity_from_aggregate!
        end)}
      rescue
        e in ArgumentError -> {:error, {:exception, e.message}}
        _ -> @error_unknown_exception
      end
    end
  end

  @spec extract_entity_from_aggregate!(agg :: CoreType.aggregate()) :: ProductEntity.t()
  defp extract_entity_from_aggregate!(agg) when is_tuple(agg) do
    product = elem(agg, 2)
    product.entity
  end
end
