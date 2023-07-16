defmodule Product.Core.Structure do

  defmodule Entity do
    @moduledoc """
    Product entity will act as AggregateRoot too which means, all product business logic
    should be happened on this module
    """
    alias Core.Structure, as: CoreStructure
    alias Core.Structure.Id
    alias Product.Category.Core.Structure.Entity, as: CategoryEntity

    @enforce_keys [:id, :category, :name, :price, :created_at]
    defstruct [:id, :category, :name, :desc, :price, :created_at, :updated_at]

    @typedoc """
    Main Product's entity properties
    """
    @type t :: %__MODULE__{
      id: Id.t(),
      category: CategoryEntity.t(),
      name: String.t(),
      desc: String.t(),
      price: non_neg_integer(),
      created_at: String.t(),
      updated_at: String.t()
    }

    @error_validation_not_passed {:error, {:validation, "invalid given new product structure"}}
    @error_invalid_new_product_type {:error, {:product_type, "invalid given new product type"}}

    @typedoc """
    new_product used to generate new entity based on
    this given values
    """
    @type new_product :: %{
      required(:name) => String.t(),
      required(:price) => non_neg_integer(),
      optional(:desc) => String.t(),
    }

    @typedoc """
    state_changes used to indicate that there are a change of internal values like
    new state from empty, or just changes inside the value itself
    """
    @type state_changes :: {:ok, t()} | CoreStructure.error()

    @doc """
    new used to generate new product's entity, including for it's id and
    created_at
    """
    @spec new(product :: new_product(), category :: CategoryEntity.t()) :: {:ok, t()} | CoreStructure.error()
    def new(product, category) when is_map(product) and is_struct(category) do
      with {:ok, product_validated} <- product
                                       |> validate_new_product,
           uid <- Id.new()
      do
        entity = %Entity{
          id: uid,
          category: category,
          name: product_validated.name,
          desc: Map.get(product, :desc),
          price: product_validated.price,
          created_at: DateTime.utc_now()
        }

        {:ok, entity}
      else
        {:error, message} -> {:error, {:internal, message}}
        {:error, {type, message}} -> {:error, {type, message}}
      end
    end

    @spec new(any(), any()) :: CoreStructure.error()
    def new(_, _), do: @error_invalid_new_product_type

    @doc """
    Change current given product's category and including update it's updated_at
    """
    @spec change_category(product :: t(), category :: CategoryEntity.t()) :: {:ok, t()}
    def change_category(product, category) when is_struct(product) and is_struct(category) do
      out =
        %{product | category: category}
        |> Map.update(:updated_at, DateTime.utc_now(), fn _ -> DateTime.utc_now() end)

      {:ok, out}
    end

    @spec change_category(any(), any()) :: CoreStructure.error()
    def change_category(_, _), do: @error_invalid_new_product_type

    @doc """
    Change current given product's name, including for it's updated_at
    """
    @spec change_name(product :: t(), name :: String.t()) :: {:ok, t()}
    def change_name(product, name) when is_struct(product) and is_binary(name) do
      out =
        %{product | name: name}
        |> Map.update(:updated_at, DateTime.utc_now(), fn _ -> DateTime.utc_now() end)

      {:ok, out}
    end

    @spec change_name(any(), any()) :: CoreStructure.error()
    def change_name(_, _), do: @error_invalid_new_product_type

    @doc """
    Change current given product's desc, including for it's updated_at
    """
    @spec change_desc(product :: t(), desc :: String.t()) :: {:ok, t()}
    def change_desc(product, desc) when is_struct(product) and is_binary(desc) do
      out =
        %{product | desc: desc}
        |> Map.update(:updated_at, DateTime.utc_now(), fn _ -> DateTime.utc_now() end)

      {:ok, out}
    end

    @spec change_desc(any(), any()) :: CoreStructure.error()
    def change_desc(_, _), do: @error_invalid_new_product_type

    @doc """
    Change current given product's price, including for it's updated_at
    """
    @spec change_price(product :: t(), price :: non_neg_integer()) :: {:ok, t()}
    def change_price(product, price) when is_struct(product) and is_integer(price) do
      out =
        %{product | price: price}
        |> Map.update(:updated_at, DateTime.utc_now(), fn _ -> DateTime.utc_now() end)

      {:ok, out}
    end

    @spec change_price(any(), any()) :: CoreStructure.error()
    def change_price(_, _), do: @error_invalid_new_product_type

    @spec validate_new_product(product :: new_product()) :: {:ok, new_product()} | CoreStructure.error()
    defp validate_new_product(product) when is_map(product) do

      required_keys =
        [:name, :price]
        |> Enum.filter(fn key ->
          if key == :price do
            product.price < 1
          end

          true
        end)
        |> Enum.reject(fn key -> Map.has_key?(product, key) end)
        |> Enum.empty?()

      case required_keys do
        false -> {:ok, product}
        true -> @error_validation_not_passed
      end

    end
  end

end
