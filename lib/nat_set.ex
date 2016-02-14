defmodule NatSet do
  @moduledoc """
  Functions for working with sets of natural numbers (i.e. non-negative integers).

  This module uses bitwise operations to represent such sets much more compactly than you would get
  when using standard MapSets.

  The `NatSet` is represented internally as a struct, therefore `%NatSet{}` can be used whenever
  there is a need to match on any `NatSet`. Note though the struct fields are private and must not
  be accessed directly. Instead, use the functions in this module.

  NatSets are stored using integers, in which each bit represents an element of the set. As
  Elixir/Erlang uses arbitrary-sized integers, the memory used by a NatSet grows dynamically as
  needed. The exact amount of memory used depends on your architecture &mdash; see [Erlang data
  types](http://erlang.org/doc/efficiency_guide/advanced.html).

  NatSets are `Enumerable` and `Collectable`.
  """

  use Bitwise

  # NatSets are divided into "slices" of at most @slice_size elements. A NatSet is a map in which
  # each key `k` is a non-negative integer called a _slice index_. The value for `k` is called a
  # _slice_, which is a non-negative integer whose bits represent the natural numbers
  #
  #    k * @slice_size, ..., (k + 1) * @slice_size - 1 .
  #
  # The least significant bit represents the first number in this sequence, etc.

  @slice_pow 8
  @slice_size (1 <<< @slice_pow) # 2^@slice_pow

  @opaque t :: %NatSet{map: %{non_neg_integer => non_neg_integer}}
  @type n :: non_neg_integer
  defstruct map: %{}

  @doc """
  Returns a new (empty) NatSet.

  ## Examples

      iex> NatSet.new
      #NatSet<[]>
  """
  @spec new :: t
  def new, do: %NatSet{}

  @doc """
  Creates a NatSet from an enumerable.

  ## Examples

      iex> NatSet.new([3, 3, 3, 2, 2, 1])
      #NatSet<[1, 2, 3]>
  """
  @spec new(Enum.t) :: t
  def new(enumerable), do: Enum.reduce(enumerable, new, &put(&2, &1))

  @doc """
  Creates a NatSet from an enumerable via the transformation function.

  ## Examples

      iex> NatSet.new([1, 2, 1], fn x -> 2 * x end)
      #NatSet<[2, 4]>
  """
  @spec new(Enum.t, (n -> n)) :: t
  def new(enumerable, transform), do: Enum.reduce(enumerable, %NatSet{}, &put(&2, transform.(&1)))

  @doc """
  Checks if `nat_set` contains `n`.

  ## Examples

      iex> nat_set = NatSet.new([1, 2, 3])
      iex> NatSet.member?(nat_set, 2)
      true
      iex> NatSet.member?(nat_set, 4)
      false
  """
  @spec member?(t, n) :: boolean
  def member?(%NatSet{} = nat_set, n) when n >= 0 do
    slice = Map.get(nat_set.map, slice_idx(n), 0)
    slice_shifted = slice >>> rem(n, @slice_size)
    (slice_shifted &&& 1) == 1
  end

  @doc """
  Ensures that the number `n` is present in `nat_set`.

  ## Examples

      iex> NatSet.put(NatSet.new([1, 2, 3]), 3)
      #NatSet<[1, 2, 3]>
      iex> NatSet.put(NatSet.new([1, 2, 3]), 4)
      #NatSet<[1, 2, 3, 4]>
  """
  @spec put(t, n) :: t
  def put(%NatSet{} = nat_set, n) when n >= 0 do
    slice = 1 <<< rem(n, @slice_size)
    Map.update!(nat_set, :map, fn map -> Map.update(map, slice_idx(n), slice, &(&1 ||| slice)) end)
  end

  @doc """
  Ensures that the number `n` is absent from `nat_set`.

  ## Examples

      iex> nat_set = NatSet.new([1, 2, 3])
      iex> NatSet.delete(nat_set, 4)
      #NatSet<[1, 2, 3]>
      iex> NatSet.delete(nat_set, 2)
      #NatSet<[1, 3]>
  """
  @spec delete(t, n) :: t
  def delete(%NatSet{} = nat_set, n) when n >= 0 do
    slice_idx = slice_idx(n)
    slice = Map.get(nat_set.map, slice_idx, 0)

    Map.update!(nat_set, :map, fn map ->
      if slice == 0 do
        Map.delete(map, slice_idx)
      else
        Map.put(map, slice_idx, slice &&& ~~~(1 <<< rem(n, @slice_size)))
      end
    end)
  end

  @doc """
  Returns the cardinality of (i.e. number of elements in) `nat_set`.

  ## Examples

      iex> NatSet.new([0, 4, 2]) |> NatSet.size
      3
  """
  @spec size(t) :: non_neg_integer
  def size(%NatSet{} = nat_set), do: nat_set |> to_stream |> Enum.count

  @doc """
  Returns the difference between `nat_set1` and `nat_set2`.

  The result is the set of all elements that are in `nat_set1` but not in `nat_set2`.

  ## Examples

      iex> NatSet.difference(NatSet.new([4, 2]), NatSet.new([2, 3]))
      #NatSet<[4]>
  """
  @spec difference(t, t) :: t
  def difference(%NatSet{} = nat_set1, %NatSet{} = nat_set2) do
    map = Enum.reduce(nat_set1.map, %{}, fn {slice_idx1, slice1}, result ->
      slice2 = Map.get(nat_set2.map, slice_idx1, 0)
      slice = slice1 &&& ~~~(slice2)
      if slice == 0 do
        result
      else
        Map.put(result, slice_idx1, slice)
      end
    end)

    %NatSet{map: map}
  end

  @doc """
  Checks if `nat_set1` and `nat_set2` have no members in common.

  ## Examples

      iex> NatSet.disjoint?(NatSet.new([1, 2]), NatSet.new([3, 4]))
      true
      iex> NatSet.disjoint?(NatSet.new([1, 2]), NatSet.new([2, 3]))
      false
  """
  @spec disjoint?(t, t) :: boolean
  def disjoint?(%NatSet{} = nat_set1, %NatSet{} = nat_set2) do
    if map_size(nat_set1) > map_size(nat_set2), do: {nat_set1, nat_set2} = {nat_set2, nat_set1}

    Enum.all?(nat_set1.map, fn {slice_idx1, slice1} ->
      (slice1 &&& Map.get(nat_set2.map, slice_idx1, 0)) == 0
    end)
  end

  @doc """
  Checks if two NatSets are equal.

  ## Examples

      iex> NatSet.equal?(NatSet.new([1, 2]), NatSet.new([2, 1]))
      true
      iex> NatSet.equal?(NatSet.new([1, 2]), NatSet.new(0..2))
      false
  """
  @spec equal?(t, t) :: boolean
  def equal?(%NatSet{} = nat_set1, %NatSet{} = nat_set2), do: Map.equal?(nat_set1.map, nat_set2.map)

  @doc """
  Returns the intersection between `nat_set1` and `nat_set2`.

  The result is the set of all elements that are in both `nat_set1` and `nat_set2`.

  ## Examples

      iex> NatSet.intersection(NatSet.new([3, 4, 2]), NatSet.new([2, 3, 1]))
      #NatSet<[2, 3]>
  """
  @spec intersection(t, t) :: t
  def intersection(%NatSet{} = nat_set1, %NatSet{} = nat_set2) do
    if map_size(nat_set1) > map_size(nat_set2), do: {nat_set1, nat_set2} = {nat_set2, nat_set1}

    map = Enum.reduce(nat_set1.map, %{}, fn {slice_idx1, slice1}, result ->
      slice = slice1 &&& Map.get(nat_set2.map, slice_idx1, 0)
      if slice == 0 do
        result
      else
        Map.put(result, slice_idx1, slice)
      end
    end)

    %NatSet{map: map}
  end

  @doc """
  Checks if all of `nat_set1`'s elements occur in `nat_set2`.

  ## Examples

      iex> NatSet.subset?(NatSet.new([1, 2]), NatSet.new([1, 2, 3]))
      true
      iex> NatSet.subset?(NatSet.new([1, 2, 3]), NatSet.new([1, 2]))
      false
  """
  @spec subset?(t, t) :: boolean
  def subset?(%NatSet{} = nat_set1, %NatSet{} = nat_set2) do
    Enum.all?(nat_set1.map, fn {slice_idx1, slice1} ->
      (slice1 &&& Map.get(nat_set2.map, slice_idx1, 0)) == slice1
    end)
  end

  @doc """
  Returns the union of `nat_set1` and `nat_set2`.

  This is the set of elements that occur in `nat_set1` or `nat_set2`.

  ## Examples

      iex> NatSet.union(NatSet.new([1, 2]), NatSet.new([2, 3]))
      #NatSet<[1, 2, 3]>
  """
  @spec union(t, t) :: t
  def union(%NatSet{} = nat_set1, %NatSet{} = nat_set2) do
    map = Map.merge(nat_set1.map, nat_set2.map, fn _slice_idx, slice1, slice2 ->
      slice1 ||| slice2
    end)

    %NatSet{map: map}
  end

  @doc """
  Converts `nat_set` into a stream of its elements in ascending order.

  ## Examples

      iex> [3, 1, 4, 2] |> NatSet.new |> NatSet.to_stream |> Enum.to_list
      [1, 2, 3, 4]
  """
  @spec to_stream(t) :: Enumerable.t
  def to_stream(%NatSet{} = nat_set) do
    nat_set.map |> Map.keys |> Stream.flat_map(fn slice_idx ->
      slice_first = slice_idx * @slice_size
      slice_last = slice_first + @slice_size - 1
      slice_first..slice_last |> Stream.filter(&member?(nat_set, &1))
    end)
  end

  @doc """
  Converts `nat_set` to a list of its elements in ascending order.

  ## Examples

      iex> [3, 1, 4, 2] |> NatSet.new |> NatSet.to_list
      [1, 2, 3, 4]
  """
  @spec to_list(t) :: [n]
  def to_list(%NatSet{} = nat_set), do: nat_set |> to_stream |> Enum.to_list

  defp slice_idx(n), do: n >>> @slice_pow

  defimpl Enumerable do
    def reduce(nat_set, acc, fun), do: nat_set |> NatSet.to_list |> Enumerable.List.reduce(acc, fun)
    def member?(nat_set, val), do: {:ok, NatSet.member?(nat_set, val)}
    def count(nat_set), do: {:ok, NatSet.size(nat_set)}
  end

  defimpl Collectable do
    def into(original) do
      {original, fn
        nat_set, {:cont, x} -> NatSet.put(nat_set, x)
        nat_set, :done -> nat_set
        _, :halt -> :ok
      end}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(nat_set, opts) do
      concat ["#NatSet<", Inspect.List.inspect(NatSet.to_list(nat_set), opts), ">"]
    end
  end
end
