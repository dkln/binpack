defmodule Binpack.Container do
  alias __MODULE__

  defstruct data: nil,
            depth: 0,
            height: 0,
            # TODO: implement configurable margins of containers
            item_margin: 0,
            width: 0,
            max_weight: 0

  @type t :: %__MODULE__{
          data: any(),
          depth: non_neg_integer(),
          height: non_neg_integer(),
          item_margin: non_neg_integer(),
          width: non_neg_integer(),
          max_weight: non_neg_integer()
        }

  @doc """
  Calculates volume of container

  ## Examples

      iex> Binpack.Container.get_volume(%Binpack.Container{height: 5, depth: 20, width: 10})
      1_000

  """
  @spec get_volume(Container.t()) :: number()
  def get_volume(%Container{} = container),
    do: container.width * container.height * container.depth

  defmodule Placement do
    alias Binpack.Item

    defstruct container: nil,
              placed_items: [],
              unfitted_items: []

    @type t :: %__MODULE__{
            container: nil | Binpack.Container.t(),
            placed_items: list(Item.Placement.t()),
            unfitted_items: list(Item.Placement.t())
          }

    @doc """
    Adds item to container

    ## Examples

        iex> item_1 = %Binpack.Item.Placement{item: %Binpack.Item{data: "1"}}
        iex> item_2 = %Binpack.Item.Placement{item: %Binpack.Item{data: "2"}}
        ...> container = %Binpack.Container.Placement{}
        ...> container.placed_items
        []
        iex> container = Binpack.Container.Placement.add_item(container, item_1)
        ...> container.placed_items
        [%Binpack.Item.Placement{item: %Binpack.Item{data: "1"}}]
        iex> container = Binpack.Container.Placement.add_item(container, item_2)
        ...> container.placed_items
        [%Binpack.Item.Placement{item: %Binpack.Item{data: "2"}}, %Binpack.Item.Placement{item: %Binpack.Item{data: "1"}}]

    """
    @spec add_item(Container.Placement.t(), Item.Placement.t()) :: Container.Placement.t()
    def add_item(%Container.Placement{} = container_placement, %Item.Placement{} = item_placement) do
      %Container.Placement{
        container_placement
        | placed_items: [item_placement | container_placement.placed_items]
      }
    end

    @doc """
    Adds unfit item to container

    ## Examples

        iex> item_1 = %Binpack.Item.Placement{item: %Binpack.Item{data: "1"}}
        iex> item_2 = %Binpack.Item.Placement{item: %Binpack.Item{data: "2"}}
        ...> container = %Binpack.Container.Placement{}
        ...> container.unfitted_items
        []
        iex> container = Binpack.Container.Placement.add_unfit_item(container, item_1)
        ...> container.unfitted_items
        [%Binpack.Item.Placement{item: %Binpack.Item{data: "1"}}]
        iex> container = Binpack.Container.Placement.add_unfit_item(container, item_2)
        ...> container.unfitted_items
        [%Binpack.Item.Placement{item: %Binpack.Item{data: "2"}}, %Binpack.Item.Placement{item: %Binpack.Item{data: "1"}}]

    """
    @spec add_unfit_item(Container.Placement.t(), Item.Placement.t()) :: Container.Placement.t()
    def add_unfit_item(
          %Container.Placement{} = container_placement,
          %Item.Placement{} = item_placement
        ) do
      %Container.Placement{
        container_placement
        | unfitted_items: [item_placement | container_placement.unfitted_items]
      }
    end

    @doc """
    Calculates the total weight inside the container

    ## Examples

        iex> item_1 = %Binpack.Item.Placement{item: %Binpack.Item{weight: 100}}
        ...> item_2 = %Binpack.Item.Placement{item: %Binpack.Item{weight: 200}}
        ...> container = %Binpack.Container.Placement{}
        ...> Binpack.Container.Placement.get_total_weight(container)
        0
        iex> container = Binpack.Container.Placement.add_item(container, item_1)
        ...> Binpack.Container.Placement.get_total_weight(container)
        100
        iex> container = Binpack.Container.Placement.add_item(container, item_2)
        ...> Binpack.Container.Placement.get_total_weight(container)
        300

    """
    @spec get_total_weight(Container.Placement.t()) :: number()
    def get_total_weight(%Container.Placement{} = container_placement) do
      container_placement.placed_items
      |> Enum.map(& &1.item.weight)
      |> Enum.sum()
    end

    @doc """
    Tests if item would fit container in it's current position and rotation

    ## Examples

        iex> item = %Binpack.Item.Placement{item: %Binpack.Item{width: 10, height: 20, depth: 15}, position: [0, 0, 0]}
        ...> container = %Binpack.Container.Placement{container: %Binpack.Container{width: 20, height: 30, depth: 20}}
        ...> Binpack.Container.Placement.is_item_within_boundaries?(container, item)
        true
        iex> item = Binpack.Item.Placement.set_position(item, [10, 0, 0])
        ...> Binpack.Container.Placement.is_item_within_boundaries?(container, item)
        true
        iex> item = Binpack.Item.Placement.set_position(item, [11, 0, 0])
        ...> Binpack.Container.Placement.is_item_within_boundaries?(container, item)
        false
        iex> item = Binpack.Item.Placement.set_position(item, [10, 0, 0])
        ...> item = Binpack.Item.Placement.set_rotation(item, 1)
        ...> Binpack.Container.Placement.is_item_within_boundaries?(container, item)
        false
        iex> item = Binpack.Item.Placement.set_rotation(item, 5)
        ...> Binpack.Container.Placement.is_item_within_boundaries?(container, item)
        true

    """
    @spec is_item_within_boundaries?(Container.Placement.t(), Item.Placement.t()) :: boolean()
    def is_item_within_boundaries?(
          %Container.Placement{} = container_placement,
          %Item.Placement{} = item_placement
        ) do
      [item_width, item_height, item_depth] = Item.Placement.get_dimension(item_placement)
      [item_x, item_y, item_z] = item_placement.position

      if container_placement.container.width < item_x + item_width ||
           container_placement.container.height < item_y + item_height ||
           container_placement.container.depth < item_z + item_depth do
        false
      else
        true
      end
    end

    @doc """
    Tests if item would fit container in it's current position and rotation

    ## Examples

        iex> item_1 = %Binpack.Item.Placement{item: %Binpack.Item{width: 10, height: 20, depth: 15}}
        ...> item_2 = %Binpack.Item.Placement{item: %Binpack.Item{width: 10, height: 20, depth: 15}, rotation: 5, position: [10, 0, 0]}
        ...> item_3 = %Binpack.Item.Placement{item: %Binpack.Item{width: 2, height: 3, depth: 4}}
        ...> container = %Binpack.Container.Placement{container: %Binpack.Container{width: 50, height: 50, depth: 50}, placed_items: [item_1, item_2]}
        ...> item_3 = Binpack.Item.Placement.set_position(item_3, [30, 0, 0])
        ...> Binpack.Container.Placement.is_not_intersecting_other_items?(container, item_3)
        true
        iex> item_3 = Binpack.Item.Placement.set_position(item_3, [1, 2, 3])
        ...> Binpack.Container.Placement.is_not_intersecting_other_items?(container, item_3)
        false

    """
    @spec is_not_intersecting_other_items?(Container.Placement.t(), Item.Placement.t()) ::
            boolean()
    def is_not_intersecting_other_items?(
          %Container.Placement{} = container_placement,
          %Item.Placement{} = item_to_place
        ) do
      Enum.all?(container_placement.placed_items, fn placed_item ->
        Item.Placement.intersects?(placed_item, item_to_place) == false
      end)
    end

    @doc """
    Tests if item would fit in container without exceeding max weight

    ## Examples

        iex> item_1 = %Binpack.Item.Placement{item: %Binpack.Item{weight: 5}}
        ...> item_2 = %Binpack.Item.Placement{item: %Binpack.Item{weight: 10}}
        ...> item_3 = %Binpack.Item.Placement{item: %Binpack.Item{weight: 15}}
        ...> container = %Binpack.Container.Placement{container: %Binpack.Container{max_weight: 30}, placed_items: [item_1, item_2]}
        ...> Binpack.Container.Placement.item_fits_in_max_weight?(container, item_3)
        true
        iex> item_3 = %Binpack.Item.Placement{item: %Binpack.Item{weight: 25}}
        ...> Binpack.Container.Placement.item_fits_in_max_weight?(container, item_3)
        false

    """
    @spec item_fits_in_max_weight?(Container.Placement.t(), Item.Placement.t()) :: boolean()
    def item_fits_in_max_weight?(
          %Container.Placement{} = container_placement,
          %Item.Placement{} = item_to_place
        ) do
      if get_total_weight(container_placement) + item_to_place.item.weight >
           container_placement.container.max_weight do
        false
      else
        true
      end
    end
  end
end
