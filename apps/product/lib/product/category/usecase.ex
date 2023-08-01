defmodule Product.Category.Usecase do
  @moduledoc """
  Category's activities will be:

  * - get_categories
  * - get_category_by_id
  * - create_new
  * - update_product_name
  * - update_product_desc
  * - remove_category
  """

  alias Core.Structure, as: CoreType
  alias Core.Structure.Function.Builder.Dependency, as: FunctionDep
  alias Product.Category.Core.Structure.Entity, as: CategoryEntity
  alias Product.Category.Core.Aggregate, as: CategoryAggregate

  @error_nil_value {:error, {:value, "has a nil value"}}
  @error_unknown_exception {:error, {:exception, "unknown exception"}}

  @spec new(repoCategory :: module(), opts :: keyword()) :: FunctionDep.t()
  def new(repoCategory, opts \\ []) when is_atom(repoCategory) and is_atom(repoCategory) do
    %FunctionDep{
      deps: %{
        :category => repoCategory
      },
      options: opts
    }
  end

  @spec get_categories(deps :: FunctionDep.t()) :: {:ok, list(CategoryEntity.t())} | CoreType.error()
  def get_categories(deps) do
    with repo <- Map.get(deps, :deps),
         {:ok, categories} <- repo.category.get_categories()
    do
      categories |> get_category_entities
    else
      nil -> @error_nil_value
      {:error, errors} -> {:error, errors}
    end
  end

  @spec get_category_by_id(deps :: FunctionDep.t(), id :: String.t()) :: {:ok, CategoryEntity.t()} | CoreType.error()
  def get_category_by_id(deps, id) when is_struct(deps) and is_binary(id) do
    with repo <- Map.get(deps, :deps),
         {:ok, category} <- repo.category.get_category_by_id(id)
    do
      try do
        # extract product's entity from current product's aggregate
        {:ok, category |> extract_entity_from_aggregate!}
      rescue
        e in ArgumentError -> {:error, {:exception, e.message}}
        _ -> @error_unknown_exception
      end
    else
      nil -> @error_nil_value
      {:error, errors} -> {:error, errors}
    end
  end

  @spec create_new(deps :: FunctionDep.t(), category :: CategoryEntity.new()) :: {:ok, CategoryEntity.t()} | CoreType.error()
  def create_new(deps, category) when is_struct(deps) and is_map(category) do
    with repo <- Map.get(deps, :deps),
         {:ok, category_agg} <- CategoryAggregate.new |> CategoryAggregate.create_new(category),
         {:ok, category_saved} <- repo.category.create_new(category_agg),
         {:ok, category_saved_agg} <- category_saved |> CategoryAggregate.aggregate
    do
      {:ok, category_saved_agg |> CategoryAggregate.entity}
    else
      nil -> @error_nil_value
      {:error, {error_type, error_msg}} -> {:error, {error_type, error_msg}}
      {:error, error_msg} -> {:error, {:internal, error_msg}}
    end
  end

  @spec update_category(deps :: FunctionDep.t(), category :: CategoryEntity.t(), id :: String.t()) :: {:ok, CategoryEntity.t()}  | CoreType.error()
  def update_category(deps, category, id) when is_struct(deps) and is_struct(category) and is_binary(id) do
    with repo <- Map.get(deps, :deps),
         {:ok, category_original_agg} <- repo.category.get_category_by_id(id),
         {:ok, category_original_agg_object} <- category_original_agg |> CategoryAggregate.aggregate,
         category_original_entity <- category_original_agg_object |> CategoryAggregate.entity,
         {:ok, category_updated_name} <- CategoryAggregate.change_name(category_original_agg, category_original_entity, category.name),
         {:ok, category_updated_name_object} <- category_updated_name |> CategoryAggregate.aggregate,
         category_name_entity <- category_updated_name_object |> CategoryAggregate.entity,
         {:ok, category_updated} <- CategoryAggregate.change_desc(category_updated_name, category_name_entity, category.desc),
         {:ok, category_saved} <- repo.category.update(category_updated),
         {:ok, category_saved_agg} <- category_saved |> CategoryAggregate.aggregate,
         category_saved_entity <- category_saved_agg |> CategoryAggregate.entity
    do
      {:ok, category_saved_entity}
    else
      nil -> @error_nil_value
      {:error, {error_type, error_msg}} -> {:error, {error_type, error_msg}}
      {:error, error_msg} -> {:error, {:internal, error_msg}}
    end
  end

  @spec remove_category(deps :: FunctionDep.t(), id :: String.t()) :: none() | CoreType.error()
  def remove_category(deps, id) when is_struct(deps) and is_binary(id) do
    with repo <- Map.get(deps, :deps),
         {:ok, category_agg} <- repo.category.get_category_by_id(id)
    do
      repo.category.remove(category_agg)
    else
      nil -> @error_nil_value
      {:error, {error_type, error_msg}} -> {:error, {error_type, error_msg}}
      {:error, error_msg} -> {:error, {:internal, error_msg}}
    end
  end

  @spec get_category_entities(category_aggregates :: list(CoreType.aggregate())) :: {:ok, list(CategoryEntity.t())} | CoreType.error()
  defp get_category_entities(category_aggregates) do
    if length(category_aggregates) < 1 do
      {:ok, []}
    else
      # need to guard our operation due to `elem/2` has possibility
      # to raise an Exception
      try do
        # extract product's entity from current category's aggregate
        {:ok, Enum.map(category_aggregates, fn aggregate ->
          aggregate
          |> extract_entity_from_aggregate!
        end)}
      rescue
        e in ArgumentError -> {:error, {:exception, e.message}}
        _ -> @error_unknown_exception
      end
    end
  end

  @spec extract_entity_from_aggregate!(agg :: CoreType.aggregate()) :: CategoryEntity.t()
  defp extract_entity_from_aggregate!(agg) when is_tuple(agg) do
    category = elem(agg, 2)
    category.entity
  end
end
