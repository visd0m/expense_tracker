defmodule Expense do
  @enforce_keys [:date, :amount, :category, :detail, :owner, :import_session_id, :metadata, :source]
  defstruct [:date, :amount, :category, :detail, :owner, :import_session_id, :metadata, :source]

  @type t :: %Expense{
          date: Date.t(),
          amount: Float.t(),
          category: String.t(),
          detail: String.t(),
          owner: String.t(),
          import_session_id: UUID.t(),
          source: String.t(),
          metadata: map()
        }

  @spec parse_amount(String.t(), Keyword.t()) :: Float.t()
  def parse_amount(amount_as_string, options \\ []) do
    defaults = %{separator: '.', decimal_separator: ','}

    options = Enum.into(options, defaults)

    case options do
      %{separator: '.', decimal_separator: ','} ->
        amount_as_string
        |> String.replace(".", "")
        |> String.replace(",", ".")
        |> Float.parse()
        |> elem(0)

      %{separator: ',', decimal_separator: '.'} ->
        amount_as_string
        |> Float.parse()
        |> elem(0)

      _ ->
        raise RuntimeError, "unhandled options"
    end
  end

  @spec parse_date(String.t(), Keyword.t()) :: Date.t()
  def parse_date(date_as_string, options \\ []) do
    defaults = %{format: "yyyy-MM-dd'T'HH:mm:ss", lang: :eng}

    options = Enum.into(options, defaults)

    case options do
      %{format: "yyyy-MM-dd", lang: _} ->
        Date.from_iso8601!(date_as_string)

      %{format: "MMM dd", lang: lang} ->
        [month_name, day] = String.split(date_as_string, " ")

        month_number =
          case lang do
            :eng ->
              case String.downcase(month_name) do
                "jan" -> "01"
                "feb" -> "02"
                "mar" -> "03"
                "apr" -> "04"
                "may" -> "05"
                "jun" -> "06"
                "jul" -> "07"
                "aug" -> "08"
                "sep" -> "09"
                "oct" -> "10"
                "nov" -> "11"
                "dec" -> "12"
              end

            _ ->
              raise RuntimeError, "unhandled lang=#{lang}"
          end

        Date.from_iso8601!("2019-#{month_number}-#{String.pad_leading(day, 2, "0")}")

      %{format: "dd MMM yyyy", lang: lang} ->
        [day, month_name, year] = String.split(date_as_string, " ")

        month_number =
          case lang do
            :ita ->
              case String.downcase(month_name) do
                "geb" -> "01"
                "feb" -> "02"
                "mar" -> "03"
                "apr" -> "04"
                "mag" -> "05"
                "giu" -> "06"
                "lug" -> "07"
                "ago" -> "08"
                "aet" -> "09"
                "ott" -> "10"
                "nov" -> "11"
                "dic" -> "12"
              end

            _ ->
              raise RuntimeError, "unhandled lang=#{lang}"
          end

        Date.from_iso8601!("#{year}-#{month_number}-#{String.pad_leading(day, 2, "0")}")

      %{format: "dd/MM/yyyy", lang: _} ->
        [day, month, year] = String.split(date_as_string, "/")

        Date.from_iso8601!("#{year}-#{month}-#{String.pad_leading(day, 2, "0")}")

      _ ->
        raise RuntimeError, "unhandled options"
    end
  end
end
