defmodule Binpack do
  @moduledoc """
  Documentation for `Binpack`.
  """

  alias Binpack.Container
  alias Binpack.Item
  alias Binpack.Pack

  @type axis :: :width | :height | :depth
  @type rotation :: 0 | 1 | 2 | 3 | 4 | 5
  @type dimension :: list(non_neg_integer())

  @spec pack(Pack.t()) :: list(Container.Placement.t())
  def pack(%Pack{} = pack) do
    containers =
      pack.containers
      |> Enum.sort_by(&Container.get_volume/1, :desc)
      |> Enum.map(fn container ->
        %Container.Placement{container: container}
      end)

    items =
      pack.items
      |> Enum.sort_by(&Item.get_volume/1, :desc)
      |> Enum.map(fn item ->
        %Item.Placement{item: item}
      end)

    {packed_containers, _packed_items} =
      containers
      |> Enum.reduce({[], items}, fn container, {containers, items} ->
        # we walk over every container
        # the reduce here is returning the container itself + the items (that might be changed)
        {updated_container, updated_items} =
          Enum.reduce(items, {container, []}, fn item, {container, items} ->
            # this walks over all items that requires to be placed

            # skip already placed item
            if item.placed do
              # just append to linked list
              {container, [item | items]}
            else
              # try to pack the item to the container
              {_fits, updated_container, updated_item} = pack_to_container(container, item)

              # append to linked list
              {updated_container, [updated_item | items]}
            end
          end)

        # since items are a linked list, we need to reverse it for the next loop
        {[updated_container | containers], Enum.reverse(updated_items)}
      end)

    Enum.reverse(packed_containers)
  end

  defp pack_to_container(
         %Container.Placement{} = container,
         %Item.Placement{} = item
       ) do
    {fits?, updated_container, updated_item} =
      if Enum.empty?(container.placed_items) do
        # container is empty, so no need to walk through the axis
        put_item_in_container(container, item, [0, 0, 0])
      else
        # container already contains items
        # walk through every axis
        Enum.reduce(0..2, {false, container, item}, fn move_axis, {fits?, container, item} ->
          if fits? do
            # skip
            {fits?, container, item}
          else
            # walk through every item that is already placed
            container.placed_items
            |> Enum.reduce({fits?, container, item}, fn placed_item, {fits?, container, item} ->
              if fits? do
                # skip
                {fits?, container, item}
              else
                # try new position
                [width, height, depth] = Item.Placement.get_dimension(placed_item)
                [position_x, position_y, position_z] = placed_item.position

                # move next to placed item
                position =
                  case move_axis do
                    0 -> [position_x + width, position_y, position_z]
                    1 -> [position_x, position_y + height, position_z]
                    2 -> [position_x, position_y, position_z + depth]
                  end

                put_item_in_container(container, item, position)
              end
            end)
          end
        end)
      end

    if fits? do
      {fits?, updated_container, updated_item}
    else
      {fits?, Container.Placement.add_unfit_item(container, item), item}
    end
  end

  defp put_item_in_container(
         %Container.Placement{} = container,
         %Item.Placement{} = item,
         position
       ) do
    if Container.Placement.item_fits_in_max_weight?(container, item) do
      {fits?, rotation} =
        Enum.reduce(0..5, {false, 0}, fn rotation, {fits?, fit_rotation} ->
          if fits? do
            # already fits, so skip other rotations
            {fits?, fit_rotation}
          else
            # set new position and rotation
            updated_item =
              item
              |> Item.Placement.set_rotation(rotation)
              |> Item.Placement.set_position(position)

            fits? =
              Container.Placement.is_item_within_boundaries?(container, updated_item, position)

            fits? =
              fits? &&
                Container.Placement.is_not_intersecting_other_items?(
                  container,
                  updated_item
                )

            if fits? do
              {true, rotation}
            else
              {false, rotation}
            end
          end
        end)

      if fits? do
        updated_item =
          item
          |> Item.Placement.set_rotation(rotation)
          |> Item.Placement.set_position(position)
          |> Item.Placement.set_placed(true)

        updated_container = Container.Placement.add_item(container, updated_item)

        {true, updated_container, updated_item}
      else
        {false, container, item}
      end
    else
      # no use to even try if item is too heavy any way
      {false, container, item}
    end
  end
end
