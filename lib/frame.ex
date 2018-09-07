defmodule Frame do
  defstruct type: :nil, ops: :nil

  def from_binary(str) do
    %Frame{ type: :bin, ops: str }
  end

  def stream(%UUID{ }) do
    :nil
  end

  def from_text!(str), do: from_text!(str, {:nil, :nil, :nil, :nil})
  def from_text!("", _), do: :ok
  def from_text!(str, {prev_ty, prev_obj, prev_ev, prev_loc}) do
    IO.inspect str
    str = String.trim_leading(str)

    # types
    {my_ty, str} = case str do
      "*" <> cdr -> UUID.from_text!(cdr, prev_ty, prev_loc)
      "#" <> _ -> {prev_ty, str}
      "@" <> _ -> {prev_ty, str}
      ":" <> _ -> {prev_ty, str}
      "'" <> _ -> {prev_ty, str}
      "!" <> _ -> {prev_ty, str}
      "^" <> _ -> {prev_ty, str}
      "=" <> _ -> {prev_ty, str}
      ">" <> _ -> {prev_ty, str}
      "," <> _ -> {prev_ty, str}
      ";" <> _ -> {prev_ty, str}
      "?" <> _ -> {prev_ty, str}
      "" -> {prev_ty, str}
        _ -> raise "cannot decode type"
    end

    # object
    {my_obj, str} = case str do
      "#" <> cdr -> UUID.from_text!(cdr, prev_obj, my_ty)
      "@" <> _ -> {prev_obj, str}
      ":" <> _ -> {prev_obj, str}
      "'" <> _ -> {prev_obj, str}
      "^" <> _ -> {prev_obj, str}
      "=" <> _ -> {prev_obj, str}
      ">" <> _ -> {prev_obj, str}
      "," <> _ -> {prev_obj, str}
      ";" <> _ -> {prev_obj, str}
      "!" <> _ -> {prev_obj, str}
      "?" <> _ -> {prev_obj, str}
      "" -> {prev_obj, str}
      _ -> raise "cannot decode object"
    end

    # event
    {my_ev, str} = case str do
      "@" <> cdr -> UUID.from_text!(cdr, prev_ev, my_obj)
      ":" <> _ -> {prev_ev, str}
      "'" <> _ -> {prev_ev, str}
      "^" <> _ -> {prev_ev, str}
      "=" <> _ -> {prev_ev, str}
      ">" <> _ -> {prev_ev, str}
      "," <> _ -> {prev_ev, str}
      ";" <> _ -> {prev_ev, str}
      "!" <> _ -> {prev_ev, str}
      "?" <> _ -> {prev_ev, str}
      "" -> {prev_ev, str}
        _ -> raise "cannot decode event"
    end

    # location
    {my_loc, str} = case str do
      ":" <> cdr -> UUID.from_text!(cdr, prev_loc, my_ev)
      "'" <> _ -> {prev_loc, str}
      "^" <> _ -> {prev_loc, str}
      "=" <> _ -> {prev_loc, str}
      ">" <> _ -> {prev_loc, str}
      "," <> _ -> {prev_loc, str}
      ";" <> _ -> {prev_loc, str}
      "!" <> _ -> {prev_loc, str}
      "?" <> _ -> {prev_loc, str}
      "" -> {prev_loc, str}
      _ -> raise "cannot decode location"
    end

    # atoms
    {my_atoms, str} = case str do
      "'" <> _ -> atoms(str, my_loc)
      "^" <> _ -> atoms(str, my_loc)
      "=" <> _ -> atoms(str, my_loc)
      ">" <> _ -> atoms(str, my_loc)
      "," <> _ -> {[], str}
      ";" <> _ -> {[], str}
      "!" <> _ -> {[], str}
      "?" <> _ -> {[], str}
      "" -> {[], str}
      _ -> raise "cannot decode atoms"
    end

    # terminator
    {my_term, str} = case str do
      ";" <> cdr -> {:raw, cdr}
      "!" <> cdr -> {:header, cdr}
      "?" <> cdr -> {:query, cdr}
      "." <> cdr -> {:end, cdr}
      "," <> cdr -> {:end, cdr}
      "" -> {:end, str}
      _ -> {:reduced, str}
    end

    op = {my_ty, my_obj, my_ev, my_loc}
    IO.inspect op
    IO.inspect my_atoms
    IO.inspect my_term

    from_text!(str, op)
  end

  defp atoms(txt, prev_uuid), do: atoms(txt, prev_uuid, [])
  defp atoms("", _, prev), do: {prev, ""}
  defp atoms(txt, prev_uuid, prev) do
    txt = String.trim_leading(txt)
    if txt == "" do
      {prev, ""}
    else
      car = String.first(txt) |> :binary.first
      cdr = String.slice(txt, 1..-1)

      case car do
        ?> ->
          {uu, cdr} = UUID.from_text!(String.trim_leading(cdr), prev_uuid, :nil)
          atoms(cdr, prev_uuid, [uu | prev])

        ?= ->
          {val, cdr} = Integer.parse(cdr)
          atoms(cdr, prev_uuid, [val | prev])

        ?^ ->  {val, cdr} = Float.parse(cdr)
          atoms(cdr, prev_uuid, [val | prev])

        ?' ->
          {str, cdr} = string(cdr, {:def, ""})
          atoms(cdr, prev_uuid, [str | prev])

        _ when prev == [] -> raise "Failed to parse any atom"
        _ -> {prev, txt}
      end
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
