defmodule Product.Structure do

  defmodule Entity do
    alias Product.Structure
    alias Core.Structure
    alias Core.Structure.Id

    @enforce_keys [:id, :name, :price, :created_at]
    defstruct [:id, :name, :desc, :price, :created_at, :updated_at]

    @error_validation_not_passed {:error, "invalid given new product structure"}
    @error_invalid_new_product_type {:error, "invalid given new product type"}

    @typedoc """
    Main Product's entity properties
    """
    @type t :: %__MODULE__{
      id: Id.t(),
      name: String.t(),
      desc: String.t(),
      price: non_neg_integer(),
      created_at: String.t(),
      updated_at: String.t()
    }

    @typedoc """
    new_product used to generate new entity based on
    this given values
    """
    @type new_product :: %{
      required(:name) => String.t(),
      required(:desc) => String.t(),
      required(:price) => non_neg_integer(),
    }

    @doc """
    new used to generate new product's entity, including for it's id and
    created_at
    """
    @spec new(product :: new_product()) :: t() | Structure.error()
    def new(product) when is_map(product) do

      validation_result =
        product
        |> validate_new_product()

      with product_validated <- validation_result,
            uid <- Id.new()
      do
        %Entity{
          id: uid,
          name: product_validated.name,
          desc: product_validated.desc,
          price: product_validated.price,
          created_at: DateTime.utc_now()
        }
      else
        err -> err
      end

    end

    def new(_), do: @error_invalid_new_product_type

    @spec validate_new_product(product :: new_product()) :: new_product() | Structure.error()
    defp validate_new_product(product) when is_map(product) do

      required_keys =
        [:name, :desc, :price]
        |> Enum.reject(fn key -> Map.has_key?(product, key) end)
        |> Enum.filter(fn key ->
          if key == :price do
            product.price < 1
          end

          true
        end)
        |> Enum.empty?()

      case required_keys do
        false -> @error_validation_not_passed
        true -> product
      end

    end
  end

  defmodule Event do
    @moduledoc """
    Event used to describe all possible product's events
    """
    alias Core.Structure, as: CoreStructure
    alias Product.Structure.Entity, as: ProductEntity

    @error_invalid_product_type "invalid given product entity type"

    @doc """
    product_created used when a new product successfully created and saved in database
    """
    @spec product_created(product :: ProductEntity.t()) :: CoreStructure.event() | CoreStructure.error()
    def product_created(product) when is_struct(product), do: {:event, :product_created, product}
    def product_created(_), do: {:error, @error_invalid_product_type}

    @doc """
    product_modified used when a new product successfully modified
    """
    @spec product_modified(product :: ProductEntity.t()) :: CoreStructure.event() | CoreStructure.error()
    def product_modified(product) when is_struct(product), do: {:event, :product_modified, product}
    def product_modified(_), do: {:error, @error_invalid_product_type}

    @doc """
    product_deleted used when a product deleted from system
    """
    @spec product_deleted(product :: ProductEntity.t()) :: CoreStructure.event() | CoreStructure.error()
    def product_deleted(product) when is_struct(product), do: {:event, :product_deleted, product}
    def product_deleted(_), do: {:error, @error_invalid_product_type}
  end
end
