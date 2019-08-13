defmodule Expense do
  @enforce_keys [
    :date,
    :amount,
    :category,
    :detail,
    :owner,
    :import_session_id,
    :metadata,
    :source
  ]
  defstruct [:date, :amount, :category, :detail, :owner, :import_session_id, :metadata, :source]

  @revolut_handled_categories ["transport", "restaurants", "groceries", "health", "shopping"]

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

  @spec parse_expense(
          list() | map(),
          :revolut | :sella | :widiba,
          String.t(),
          UUID.t()
        ) :: Expense.t()
  def parse_expense(expense, source, owner, import_session_id)

  ## revolut

  def parse_expense(
        revolut_record = %{
          "Completed Date" => date,
          "Paid Out (EUR)" => paid_out,
          "Paid In (EUR)" => paid_in,
          "Exchange Out" => _exchange_out,
          "Exchange In" => _exchange_in,
          "Balance (EUR)" => _balance
        },
        :revolut,
        owner,
        import_session_id
      ) do
    amount =
      if paid_out != "",
        do: Expense.parse_amount(paid_out) * -1,
        else: Expense.parse_amount(paid_in)

    options =
      case owner do
        "sara" -> [format: "MMM dd", lang: :eng]
        "domenico" -> [format: "dd MMM yyyy", lang: :ita]
      end

    {category, detail} = revolut_get_category_and_detail(revolut_record)

    %Expense{
      amount: amount,
      category:
        category
        |> Atom.to_string()
        |> String.upcase(),
      detail: detail,
      date: date |> Expense.parse_date(options),
      owner: owner,
      metadata: %{csv: revolut_record},
      import_session_id: import_session_id,
      source: "REVOLUT"
    }
  end

  ## sella

  def parse_expense(
        sella_record = %{
          "Codice identificativo" => _id,
          "Data Contabile" => date,
          "Data valuta" => _another_date,
          "Descrizione" => description,
          "Divisa" => _currency,
          "Importo" => amount
        },
        :sella,
        owner,
        import_session_id
      ) do
    description = String.downcase(description)

    category =
      cond do
        String.contains?(description, "satispay s.p.a.") -> :salary_domenico
        String.contains?(description, "fastweb") -> :bills
        String.contains?(description, "estra") -> :bills
        String.contains?(description, "affitto immobile") -> :rent
        true -> :extra
      end

    %Expense{
      amount: amount |> Expense.parse_amount(),
      category:
        category
        |> Atom.to_string()
        |> String.upcase(),
      detail: description |> String.downcase(),
      date: date |> Expense.parse_date(format: "dd/MM/yyyy"),
      owner: owner,
      metadata: %{csv: sella_record},
      import_session_id: import_session_id,
      source: "SELLA"
    }
  end

  ## widiba

  def parse_expense(
        xls_record = [_ | [date | [_ | [detail | [amount | _]]]]],
        :widiba,
        owner,
        import_session_id
      ) do
    description = String.downcase(detail)

    category =
      cond do
        String.contains?(description, "accredito") ->
          :widiba_topup

        String.contains?(description, "addebito") && String.contains?(description, "satispay") ->
          :satispay_topup

        true ->
          :extra
      end

    %Expense{
      amount: amount,
      category:
        category
        |> Atom.to_string()
        |> String.upcase(),
      detail: detail |> String.downcase(),
      date: date,
      owner: owner,
      metadata: %{xls: xls_record},
      import_session_id: import_session_id,
      source: "WIDIBA"
    }
  end

  ###

  defp revolut_get_category_and_detail(%{
         "Description" => description,
         "Category" => category
       }) do
    revolut_get_category_and_detail(description, category)
  end

  defp revolut_get_category_and_detail(%{
         "Category" => category,
         "Reference" => reference
       }) do
    revolut_get_category_and_detail(reference, category)
  end

  defp revolut_get_category_and_detail(detail, category) do
    if Enum.member?(@revolut_handled_categories, category) do
      {String.to_existing_atom(category), detail}
    else
      cond do
        String.contains?(detail, "top-up") -> {:revolut_topup, detail}
        true -> {:extra, detail}
      end
    end
  end

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
                "june" -> "06"
                "july" -> "07"
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
                "gen" -> "01"
                "feb" -> "02"
                "mar" -> "03"
                "apr" -> "04"
                "mag" -> "05"
                "giu" -> "06"
                "lug" -> "07"
                "ago" -> "08"
                "set" -> "09"
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
