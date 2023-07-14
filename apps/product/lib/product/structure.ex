defmodule Product.Structure do

  @typep error_reason :: String.t()

  @type error :: {:error, error_reason()}
  @type ok :: {:ok, any()}

  defmodule Id do
    @moduledoc """
    Id is a value object specific for unique for id. Actually it is just
    a string of UUID but has been modified to be more short and can be
    decoded back to it's original format
    """
    alias User.Structure

    @typedoc """
    It's base original type of this value object, it is a String
    """
    @type t :: String.t()

    @doc """
    Generate new UUID and pipe it to ShortUUID for more compact format
    """
    @spec new() :: t() | Structure.error()
    def new() do
      out = UUID.uuid4() |> ShortUUID.encode()
      case out do
        {:ok, uid} -> uid
        _ -> out
      end
    end

    @doc """
    Decode given shorted uid to it's original format, which is UUID
    """
    @spec decode(shorted :: String.t()) :: t() | Structure.error()
    def decode(shorted) do
      out = shorted |> ShortUUID.decode()
      case out do
        {:ok, original} -> original
        _ -> out
      end
    end
  end

  defmodule Entity do
    alias Product.Structure
    alias Product.Structure.{Id}

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

end
