defmodule Binpack.Item do
  alias __MODULE__

  defstruct width: 0,
            height: 0,
            depth: 0,
            weight: 0,
            data: nil

  @type t :: %__MODULE__{
          width: non_neg_integer(),
          height: non_neg_integer(),
          depth: non_neg_integer(),
          weight: non_neg_integer(),
          data: any()
        }

  @doc """
  Calculates volume of item

  ## Examples

      iex> Binpack.Item.get_volume(%Binpack.Item{height: 5, depth: 20, width: 10})
      1_000

  """
  @spec get_volume(Item.t()) :: number()
  def get_volume(%Item{} = item), do: item.width * item.height * item.depth

  defmodule Placement do
    @axis_width 0
    @axis_height 1
    @axis_depth 2

    @rotations [
      [:width, :height, :depth],
      [:height, :width, :depth],
      [:height, :depth, :width],
      [:depth, :height, :width],
      [:depth, :width, :height],
      [:width, :depth, :height]
    ]

    defstruct item: nil,
              placed: false,
              position: [0, 0, 0],
              rotation: 0

    @type t :: %__MODULE__{
            item: nil | Binpack.Item.t(),
            placed: boolean(),
            position: list(number()),
            rotation: number()
          }

    @doc """
    Sets new position of item

    ## Examples

        iex> item = %Binpack.Item.Placement{}
        ...> item.position
        [0, 0, 0]
        iex> item = Binpack.Item.Placement.set_position(item, [1, 2, 3])
        ...> item.position
        [1, 2, 3]

    """
    @spec set_position(Item.Placement.t(), list(number())) :: Item.Placement.t()
    def set_position(%Item.Placement{} = item_placement, position) when is_list(position),
      do: %Item.Placement{item_placement | position: position}

    @doc """
    Sets new rotation of item

    ## Examples

        iex> item = %Binpack.Item.Placement{}
        ...> item.rotation
        0
        iex> item = Binpack.Item.Placement.set_rotation(item, 3)
        ...> item.rotation
        3

    """
    @spec set_rotation(Item.Placement.t(), number()) :: Item.Placement.t()
    def set_rotation(%Item.Placement{} = item_placement, rotation) when is_number(rotation),
      do: %Item.Placement{item_placement | rotation: rotation}

    @doc """
    Sets placed flag

    ## Examples

        iex> item = %Binpack.Item.Placement{}
        ...> item.placed
        false
        iex> item = Binpack.Item.Placement.set_placed(item, true)
        ...> item.placed
        true

    """
    @spec set_placed(Item.Placement.t(), boolean()) :: Item.Placement.t()
    def set_placed(%Item.Placement{} = item_placement, value) when is_boolean(value),
      do: %Item.Placement{item_placement | placed: value}

    @doc """
    Retrieves dimensions from given Item.Placement
    Takes rotation into account

    ## Examples

        iex> item = %Binpack.Item.Placement{item: %Binpack.Item{width: 5, height: 10, depth: 15}, rotation: 0}
        ...> Binpack.Item.Placement.get_dimension(item)
        [5, 10, 15]
        iex> item = Binpack.Item.Placement.set_rotation(item, 1)
        ...> Binpack.Item.Placement.get_dimension(item)
        [10, 5, 15]
        iex> item = Binpack.Item.Placement.set_rotation(item, 2)
        ...> Binpack.Item.Placement.get_dimension(item)
        [10, 15, 5]
        iex> item = Binpack.Item.Placement.set_rotation(item, 3)
        ...> Binpack.Item.Placement.get_dimension(item)
        [15, 10, 5]
        iex> item = Binpack.Item.Placement.set_rotation(item, 4)
        ...> Binpack.Item.Placement.get_dimension(item)
        [15, 5, 10]
        iex> item = Binpack.Item.Placement.set_rotation(item, 5)
        ...> Binpack.Item.Placement.get_dimension(item)
        [5, 15, 10]

    """
    @spec get_dimension(Item.Placement.t()) :: list(number())
    def get_dimension(%Item.Placement{} = item) do
      @rotations
      |> Enum.at(item.rotation)
      |> Enum.map(&Map.get(item.item, &1))
    end

    @doc """
    Tests if item 1 and item 2 are clashing positions

    ## Examples

        iex> item_1 = %Binpack.Item.Placement{position: [0, 0, 0], item: %Binpack.Item{width: 5, height: 10, depth: 15}}
        ...> item_2 = %Binpack.Item.Placement{position: [0, 0, 0], item: %Binpack.Item{width: 3, height: 8, depth: 13}}
        ...> Binpack.Item.Placement.intersects?(item_1, item_2)
        true
        iex> item_1 = Binpack.Item.Placement.set_position(item_1, [6, 0, 0])
        ...> Binpack.Item.Placement.intersects?(item_1, item_2)
        false
        iex> item_1 = Binpack.Item.Placement.set_rotation(item_1, 1)
        ...> Binpack.Item.Placement.intersects?(item_1, item_2)
        true

    """
    @spec intersects?(Item.Placement.t(), Item.Placement.t()) :: boolean()
    def intersects?(%Item.Placement{} = item_1, %Item.Placement{} = item_2) do
      rectangle_intersect?(item_1, item_2, @axis_width, @axis_height) &&
        rectangle_intersect?(item_1, item_2, @axis_height, @axis_depth) &&
        rectangle_intersect?(item_1, item_2, @axis_width, @axis_depth)
    end

    defp rectangle_intersect?(%Item.Placement{} = item_1, %Item.Placement{} = item_2, x, y) do
      dimension_item_1 = Item.Placement.get_dimension(item_1)
      dimension_item_2 = Item.Placement.get_dimension(item_2)

      cx_1 = Enum.at(item_1.position, x) + Enum.at(dimension_item_1, x) / 2
      cy_1 = Enum.at(item_1.position, y) + Enum.at(dimension_item_1, y) / 2
      cx_2 = Enum.at(item_2.position, x) + Enum.at(dimension_item_2, x) / 2
      cy_2 = Enum.at(item_2.position, y) + Enum.at(dimension_item_2, y) / 2

      ix = Enum.max([cx_1, cx_2]) - Enum.min([cx_1, cx_2])
      iy = Enum.max([cy_1, cy_2]) - Enum.min([cy_1, cy_2])

      ix < Enum.at(dimension_item_1, x) + Enum.at(dimension_item_2, x) / 2 &&
        iy < Enum.at(dimension_item_1, y) + Enum.at(dimension_item_2, y) / 2
    end
  end
end
