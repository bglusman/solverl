defmodule MinizincData do
  @moduledoc """
    Functions for converting data between Minizinc and Elixir.
  """

  @type data_chunk() :: Path.t() | map()
  @type mzn_data() :: data_chunk() | list(data_chunk)

  @element_separator ", "
  @default_array_base 1
  @max_dimensions 6

  ## Merges list of dzn files and/or maps and writes the result to a (temporary by default) target file.

  def make_dzn([]) do
    nil
  end


  def make_dzn(data) when is_list(data) do
     Enum.reduce(data, "",
      fn d, acc ->
        acc <> read_dzn(d) <> "\n"
      end)
  end

  def make_dzn(data) when is_binary(data) or is_map(data) do
    make_dzn([data])
  end


  # Dzn as filename
  defp read_dzn(data) when is_binary(data) do
    File.read!(data)
  end

  # Dzn as dict/map
  defp read_dzn(data) when is_map(data) do
    map_to_dzn(data)
  end

  # Convert map to the list of strings in .dzn format
  defp map_to_dzn(data) do
    Enum.reduce(
      data,
      "",
      fn ({k, v}, acc) ->
        "#{k} = #{elixir_to_dzn(v)};\n" <> acc
      end
    )
  end

  def output_to_elixir(data_dict) do
    Enum.reduce(
      data_dict,
      %{},
      fn ({k, v}, acc) ->
        Map.put(acc, k, dzn_to_elixir(v))
      end
    )
  end

  defp dzn_to_elixir(el) when is_map(el) do
    #s = el["set"]
    #if s == [], do: MapSet.new(s), else: MapSet.new(hd(s))
    [map_type] = Map.keys(el)
    case map_type do
      "set" ->
        MapSet.new(List.flatten(el["set"]))
      "e" ->
        el["e"]
      _unknown ->
        throw {:unknown_map_type, map_type}
    end

  end

  defp dzn_to_elixir(el) when is_list(el) do
    Enum.map(el, fn e -> dzn_to_elixir(e) end)
  end

  defp dzn_to_elixir(el) do
    el
  end



  #############################################
  # Convert element to .dzn string
  #############################################

  def elixir_to_dzn(array) when is_list(array) do
    array_to_dzn(array, @default_array_base)
  end

  # Support optional list of index bases for array dimensions.
  #
  def elixir_to_dzn({bases, array}) when is_list(array) do
    array_to_dzn(array, bases)
  end

  #
  # Sets
  #
  def elixir_to_dzn(map) when is_map(map) do
    "{" <> Enum.join(map, @element_separator) <> "}"
  end

  def elixir_to_dzn(enum) when is_tuple(enum) do
    enum_list = Tuple.to_list(enum)
    "{" <> Enum.join(
             Enum.map(enum_list, fn e -> "#{e}" end),
             @element_separator
           ) <> "}"
  end

  def elixir_to_dzn(el) do
    el
  end


  defp array_to_dzn(el, bases)  do
    dims = dimensions(el)
    if dims do
      array_dimensions(dims, make_base_list(dims, bases))
      <> "[#{Enum.join(List.flatten(el), @element_separator)}]" <> ")"
    else
      throw {:irregular_array, el}
    end
  end

  defp make_base_list(_dims, base) when is_list(base) do
    base
  end

  defp make_base_list(dims, base) when is_integer(base) do
    List.duplicate(base, length(dims))
  end

  defp array_dimensions(dims, _bases) when length(dims) > @max_dimensions do
    throw {:too_many_dimensions, "#{length(dims)}"}
  end

  defp array_dimensions(dims, bases) do
    if length(dims) == length(bases) do
      "array#{length(dims)}d(" <>
      Enum.reduce(
        Enum.zip(dims, bases),
        "",
        fn {d, b}, acc ->
          acc <> "#{b}..#{d + b - 1},"
          ## Shift upper bound to match dimension base
        end
      )
    else
      throw {:base_list_mismatch, bases}
    end

  end

  ## Dimensions of a nested list of lists.
  ## The lengths of sublists within a dimension have to be the same,
  ## for results, think of a proper matrix, where each row has the same number of columns etc.

  @doc false
  def dimensions(array) when is_list(array) do
    dimensions(array, [])
  end

  def dimensions(_el) do
    []
  end

  defp dimensions([], _acc) do
    []
  end

  defp dimensions(array, acc) when is_list(array) do
    [head | tail] = array
    Enum.all?(tail, fn t -> dimensions(t) == dimensions(head) end) and
    dimensions(head, [length(array) | acc])
  end

  defp dimensions(_el, acc) do
    Enum.reverse(acc)
  end

  ## Check dzn against the model info.
  ## Currently only checking for unassigned pars
  ##
  def check_dzn(model_info) do
    model_pars = MapSet.new(Map.keys(model_info[:pars]))
    if Enum.empty?(model_pars) do
      :ok
    else
      {:error, {:unassigned_pars, model_pars}}
    end
  end


end
