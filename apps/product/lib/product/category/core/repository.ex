defmodule Product.Category.Core.Repository do
  alias Core.Structure, as: CoreStructure

  @callback get_categories() :: {:ok, list(CoreStructure.aggregate())} | CoreStructure.error()
  @callback get_category_by_id(id :: String.t()) :: {:ok, CoreStructure.aggregate()} | CoreStructure.error()
  @callback create_new(category_aggregate :: CoreStructure.aggregate()) :: {:ok, CoreStructure.aggregate()} | CoreStructure.error()
  @callback update(category_aggregate :: CoreStructure.aggregate()) :: {:ok, CoreStructure.aggregate()} | CoreStructure.error()
  @callback remove(category_aggregate :: CoreStructure.aggregate()) :: none() | CoreStructure.error()
end
