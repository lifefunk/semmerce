defmodule Product.Core.Repository do
  @moduledoc """
  Provide base abstraction for product's repository interface.
  This module provide an abstraction only for product's aggregate, which
  on this case our product's entity is an aggregate root, following concept
  1 aggregate 1 repository.

  What behaviors need to?
  - get all products
  - get all products based on specific category
  - get product by id
  - save product
  - remove product
  """
  alias Core.Structure, as: CoreStructure
  alias Product.Core.Aggregate, as: ProductAggregate
  alias Product.Core.Structure.Entity, as: ProductEntity

  @doc """
  Get all products
  """
  @callback get_products() :: {:ok, list(ProductEntity.t())} | CoreStructure.error()

  @doc """
  Get all products by category_id
  """
  @callback get_products_by_category_id(category_id :: String.t()) :: {:ok, list(ProductEntity.t())} | CoreStructure.error()

  @doc """
  Get detail product by id
  """
  @callback get_product_by_id(id :: String.t()) :: {:ok, ProductEntity.t()} | CoreStructure.error()

  @doc """
  Save product. Given argument will be product's aggregate
  """
  @callback save(product_aggregate :: ProductAggregate.t()) :: {:ok, ProductAggregate.t()} | CoreStructure.error()

  @doc """
  Remove product, given argument will be product's aggregate
  """
  @callback remove(product_aggregate :: ProductAggregate.t()) :: {:ok, ProductAggregate.t()} | CoreStructure.error()
end
