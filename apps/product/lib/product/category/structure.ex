defmodule Product.Category.Structure do
  defmodule Entity do
    @moduledoc """
    This is a main entity for product's category. A product
    will be related to some category. Category will have many products, from
    database perspective
    """
    alias Core.Structure, as: CoreStructure
    alias Core.Structure.Id, as: CoreId

    @enforce_keys [:id, :name, :created_at]
    defstruct [:id, :name, :desc, :created_at, :updated_at]

    @error_validation_not_passed {:error, "invalid given new product structure"}

    @typedoc """
    Main type for category entity
    """
    @type t :: %__MODULE__{
      id: CoreId.t(),
      name: String.t(),
      desc: String.t(),
      created_at: DateTime.t(),
      updated_at: DateTime.t() | nil
    }

    @typedoc """
    new_category is a given payload to create category's entity
    """
    @type new_category :: %{
      required(:name) => String.t(),
      optional(:desc) => String.t()
    }

    @doc """
    Create Category entity from given new_category payload. It will return
    an entity or an error tuple
    """
    @spec new(category :: new_category()) :: t() | CoreStructure.error()
    def new(category) when is_map(category) do
      validation_result =
        category
        |> validate_new_category()

        with category_validated <- validation_result,
            uid <- CoreId.new()
      do
        %Entity{
          id: uid,
          name: category_validated.name,
          desc: Map.get(category, :desc),
          created_at: DateTime.utc_now()
        }
      else
        err -> err
      end
    end

    @spec validate_new_category(category :: new_category()) :: new_category() | CoreStructure.error()
    defp validate_new_category(category) when is_map(category) do
      required_keys =
        [:name]
        |> Enum.reject(fn key -> Map.has_key?(category, key) end)
        |> Enum.empty?()

      case required_keys do
        false -> {:error, @error_validation_not_passed}
        true -> category
      end
    end
  end

  defmodule Event do
    @moduledoc """
    Describe all possible category events
    """
    alias Core.Structure, as: CoreStructure
    alias Product.Category.Structure.Entity, as: CategoryEntity

    @error_invalid_category_type "invalid given category entity type"

    @doc """
    Used when category successfully created
    """
    @spec category_created(category :: CategoryEntity.t()) :: CoreStructure.event() | CoreStructure.error()
    def category_created(category) when is_struct(category), do: {:event, :category_created, category}
    def category_created(_), do: {:error, @error_invalid_category_type}

    @doc """
    Used when category successfully edited
    """
    @spec category_edited(category :: CategoryEntity.t()) :: CoreStructure.event() | CoreStructure.error()
    def category_edited(category) when is_struct(category), do: {:event, :category_edited, category}
    def category_edited(_), do: {:error, @error_invalid_category_type}

    @doc """
    Used when category successfully deleted
    """
    @spec category_deleted(category :: CategoryEntity.t()) :: CoreStructure.event() | CoreStructure.error()
    def category_deleted(category) when is_struct(category), do: {:event, :category_deleted, category}
    def category_deleted(_), do: {:error, @error_invalid_category_type}
  end
end
