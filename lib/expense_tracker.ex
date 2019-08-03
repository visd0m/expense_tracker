defmodule ExpenseTracker do
  @spec track ::
          {:error, Tesla.Env.t()} | {:ok, GoogleApi.Sheets.V4.Model.AppendValuesResponse.t()}
  def track do
    configuration = Configuration.load_configuration("config/config.json")

    import_session_id = UUID.uuid4()

    expenses =
      configuration.report_files
      |> Enum.flat_map(&handle_report(import_session_id, &1))

    ExpenseUploader.upload_expenses(expenses, configuration.spreadsheet_id)
  end

  defp handle_report(
         import_session_id,
         %{source: source, file_path: file_path, owner: owner} = %ReportFile{source: "sella"}
       ) do
    IO.puts("handling report with source=#{source}, owner=#{owner}, file_path=#{file_path}")

    file_path
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(separator: ?,, headers: true, strip_fields: true)
    |> Enum.filter(&(elem(&1, 0) == :ok))
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(fn sella_record ->
      description = sella_record["Descrizione"]

      category =
        cond do
          String.contains?(description, "SATISPAY S.P.A.") -> "STIPENDIO_DOME"
          String.contains?(description, "FASTWEB") -> "BOLLETTE"
          String.contains?(description, "AFFITTO IMMOBILE") -> "AFFITTO"
          true -> "EXTRA"
        end

      %Expense{
        amount: sella_record["Importo"] |> Expense.parse_amount(),
        category: category,
        detail: sella_record["Descrizione"],
        date: sella_record["Data Contabile"] |> Expense.parse_date(format: "dd/MM/yyyy"),
        owner: owner,
        metadata: %{csv: sella_record},
        import_session_id: import_session_id,
        source: "SELLA"
      }
    end)
    |> Enum.into([])
  end

  defp handle_report(
         import_session_id,
         %{source: source, file_path: file_path, owner: owner} = %ReportFile{source: "revolut"}
       ) do
    IO.puts("handling report with source=#{source}, owner=#{owner}, file_path=#{file_path}")

    file_path
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(separator: ?;, headers: true, strip_fields: true)
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(fn revolut_record ->
      amount =
        if revolut_record["Paid Out (EUR)"] != "",
          do: Expense.parse_amount(revolut_record["Paid Out (EUR)"]) * -1,
          else: Expense.parse_amount(revolut_record["Paid In (EUR)"])

      options =
        case owner do
          "SARA" -> [format: "MMM dd", lang: :eng]
          "DOMENICO" -> [format: "dd MMM yyyy", lang: :ita]
        end

      reference = revolut_record["Reference"]

      detail =
        if reference != "" && reference != nil,
          do: reference,
          else: revolut_record["Description"]

      %Expense{
        amount: amount,
        category: revolut_record["Category"] |> String.upcase(),
        detail: detail,
        date: revolut_record["Completed Date"] |> Expense.parse_date(options),
        owner: owner,
        metadata: %{csv: revolut_record},
        import_session_id: import_session_id,
        source: "REVOLUT"
      }
    end)
    |> Enum.into([])
  end

  defp handle_report(
         import_session_id,
         %{source: source, file_path: file_path, owner: owner} = %ReportFile{source: "widiba"}
       ) do
    IO.puts("handling report with source=#{source}, owner=#{owner}, file_path=#{file_path}")

    file_path
    |> Path.expand(__DIR__)
    |> Xlsxir.stream_list(0)
    |> Enum.map(fn xls_record ->
      xls_record
      |> Enum.filter(fn item -> item != nil end)
      |> Enum.into([])
    end)
    |> Enum.filter(&(Enum.count(&1) == 5))
    |> Enum.map(fn xls_record ->
      description = Enum.at(xls_record, 3)

      %Expense{
        amount: Enum.at(xls_record, 4),
        category:
          cond do
            String.contains?(description, "Addebito") && String.contains?(description, "Satispay") ->
              "SATISPAY_OUT"

            true ->
              "EXTRA"
          end,
        detail: Enum.at(xls_record, 3),
        date: Enum.at(xls_record, 1),
        owner: owner,
        metadata: %{xls: xls_record},
        import_session_id: import_session_id,
        source: "WIDIBA"
      }
    end)
    |> Enum.into([])
  end
end
