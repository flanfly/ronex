defmodule Op do
  defstruct type: :nil, object: :nil, event: UUID.now(), location: :nil, atoms: [], term: :raw

  def parse(str, %Op{ type: prev_ty, object: prev_obj, event: prev_ev, location: prev_loc}) do

    str = String.trim_leading(str)
    prefixes = ["#", "@", ":", "'", "!", "^", "=", ">", ",", ";", "?"]

    # type
    case spec_uuid(str, "*", prev_ty, prev_loc, prefixes) do
      {:ok, {my_ty, str}} ->
        prefixes = Enum.slice(prefixes, 1..-1)
        str = String.trim_leading(str)

        # object
        case spec_uuid(str, "#", prev_obj, my_ty, prefixes) do
          {:ok, {my_obj, str}} ->
            prefixes = Enum.slice(prefixes, 1..-1)
            str = String.trim_leading(str)

            # event
            case spec_uuid(str, "@", prev_ev, my_obj, prefixes) do
              {:ok, {my_ev, str}} ->
                prefixes = Enum.slice(prefixes, 1..-1)
                str = String.trim_leading(str)

                # location
                case spec_uuid(str, ":", prev_loc, my_ev, prefixes) do
                  {:ok, {my_loc, str}} ->
                    str = String.trim_leading(str)

                    # atoms
                    atoms_res = case str do
                      "'" <> _ -> atoms(str, my_loc)
                      "^" <> _ -> atoms(str, my_loc)
                      "=" <> _ -> atoms(str, my_loc)
                      ">" <> _ -> atoms(str, my_loc)
                      "," <> _ -> {:ok, {[], str}}
                      ";" <> _ -> {:ok, {[], str}}
                      "!" <> _ -> {:ok, {[], str}}
                      "?" <> _ -> {:ok, {[], str}}
                      _ -> {:ok, {[], str}}
                    end

                    case atoms_res do
                      {:ok, {my_atoms, str}} ->
                        str = String.trim_leading(str)

                        # terminator
                        {my_term, str} = case str do
                          ";" <> cdr -> {:raw, cdr}
                          "!" <> cdr -> {:header, cdr}
                          "?" <> cdr -> {:query, cdr}
                          "," <> cdr -> {:reduced, cdr}
                          _ -> {:reduced, str}
                        end

                        op = %Op{
                          type: my_ty, object: my_obj, event: my_ev,
                          location: my_loc, atoms: my_atoms,
                          term: my_term
                        }
                        {:ok, {op, String.trim_leading(str)}}

                      err -> err
                    end

                  # location
                  err -> err
                end

              # event
              err -> err
            end

          # object
          err -> err
        end

      # type
      err -> err
    end
  end

  defp atoms(txt, prev_uuid), do: atoms(txt, prev_uuid, [])
  defp atoms("", _, prev), do: {:ok, {prev, ""}}
  defp atoms(txt, prev_uuid, prev) do
    txt = String.trim_leading(txt)
    if txt == "" do
      {:ok, {prev, ""}}
    else
      car = String.first(txt) |> :binary.first
      cdr = String.slice(txt, 1..-1)

      case car do
        ?> ->
          case UUID.parse(String.trim_leading(cdr), prev_uuid, :nil) do
            {:ok, {uu, cdr}} ->
              atoms(cdr, prev_uuid, [uu | prev])
            {:error, msg} -> {:error, msg}
          end

        ?= ->
          {val, cdr} = Integer.parse(cdr)
          atoms(cdr, prev_uuid, [val | prev])

        ?^ ->  {val, cdr} = Float.parse(cdr)
          atoms(cdr, prev_uuid, [val | prev])

        ?' ->
          {str, cdr} = string(cdr, {:def, ""})
          atoms(cdr, prev_uuid, [str | prev])

        _ when prev == [] -> {:error, "Failed to parse any atom"}
        _ -> {:ok, {prev, txt}}
      end
    end
  end

  defp spec_uuid(str, spec, default, row_prev, skip) do
    str = String.trim_leading(str)
    cond do
      str == "" ->
        {:ok, {default, str}}
      String.first(str) == spec ->
        UUID.parse(String.slice(str, 1..-1), default, row_prev)
      Enum.member?(skip, String.first(str)) ->
        {:ok, {default, str}}
      true ->
        {:error, "cannot decode spec uuid. Got " <> str}
    end
  end

  defp string(txt, {state, str}) do
    car = String.first(txt) |> :binary.first
    cdr = String.slice(txt, 1..-1)

    case car do
      ?' when state == :def ->
        {str, cdr}
      ?' when state == :esc ->
        string(cdr, {:def, str <> "'"})
      ?\\ when state == :def ->
        string(cdr, {:esc, str})
      ?\\ when state == :esc ->
        string(cdr, {:def, str <> "\\"})
      _ when state == :def ->
        string(cdr, {:def, str <> String.first(txt)})
      ?n when state == :esc ->
        string(cdr, {:def, str <> "\n"})
      ?t when state == :esc ->
        string(cdr, {:def, str <> "\t"})
      # XXX: more escape seqs
    end
  end
end

defimpl String.Chars, for: Op do
  def to_string(%Op{ type: ty, event: ev, object: obj, location: loc, term: term, atoms: atoms }) do
    "*" <> Kernel.to_string(ty)
      <> "#" <> Kernel.to_string(obj)
      <> "@" <> Kernel.to_string(ev)
      <> ":" <> Kernel.to_string(loc)
      <> Enum.reduce(atoms, "", fn
        i, acc when is_integer(i) -> acc <> "=" <> Kernel.to_string(i)
        f, acc when is_float(f) -> acc <> "^" <> Kernel.to_string(f)
        u = %UUID{}, acc -> acc <> "=" <> Kernel.to_string(u)
        s, acc -> acc <> "'" <> s <> "'"
      end)
      <> case term do
        :raw -> ";"
        :reduced -> ","
        :header -> "!"
        :query -> "?"
      end
  end
end

