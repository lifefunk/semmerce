defmodule Product.Category.Core.Repository do
  alias Core.Structure, as: CoreStructure
  alias Product.Category.Core.Aggregate, as: CategoryAggregate

  @callback get_categories() :: {:ok, list(CategoryAggregate.t())} | CoreStructure.error()
  @callback get_category_by_id(id :: String.t()) :: {:ok, CategoryAggregate.t()} | CoreStructure.error()
  @callback create_new(category_aggregate :: CategoryAggregate.t()) :: {:ok, CategoryAggregate.t()} | CoreStructure.error()
  @callback update_name(category_aggregate :: CategoryAggregate.t()) :: {:ok, CategoryAggregate.t()} | CoreStructure.error()
  @callback update_desc(category_aggregate :: CategoryAggregate.t()) :: {:ok, CategoryAggregate.t()} | CoreStructure.error()
  @callback remove(category_aggregate :: CategoryAggregate.t()) :: {:ok, CategoryAggregate.t()} | CoreStructure.error()
end
