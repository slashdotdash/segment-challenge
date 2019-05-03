defimpl Vex.Blank, for: NaiveDateTime do
  def blank?(nil), do: true
  def blank?(%NaiveDateTime{}), do: false
end
