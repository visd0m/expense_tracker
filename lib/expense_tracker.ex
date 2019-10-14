defmodule ExpenseTracker do
  @spec track ::
          {:error, Tesla.Env.t()} | {:ok, GoogleApi.Sheets.V4.Model.AppendValuesResponse.t()}
  def track do
    configuration = Configuration.load_configuration("config/config.json")

    import_session_id = UUID.uuid4()

    expenses =
      Enum.flat_map(
        configuration.report_files,
        &handle_report(import_session_id, &1)
      )

    ExpenseUploader.upload_expenses(expenses, configuration.spreadsheet_id)
  end

  @spec handle_report(UUID.t(), ReportFile.t()) :: [Expense.t()]
  defp handle_report(
         import_session_id,
         %ReportFile{source: "sella", file_path: file_path, owner: owner}
       ) do
    IO.puts("handling sella report with owner=#{owner}, file_path=#{file_path}")

    file_path
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(separator: ?,, headers: true, strip_fields: true)
    |> Enum.filter(&(elem(&1, 0) == :ok))
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(
      &Expense.parse_expense(
        &1,
        :sella,
        owner
        |> String.downcase(),
        import_session_id
      )
    )
    |> Enum.into([])
  end

  defp handle_report(
         import_session_id,
         %ReportFile{source: "revolut", file_path: file_path, owner: owner}
       ) do
    IO.puts("handling revolut report with owner=#{owner}, file_path=#{file_path}")

    file_path
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(separator: ?;, headers: true, strip_fields: true)
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(
      &Expense.parse_expense(
        &1,
        :revolut,
        owner
        |> String.downcase(),
        import_session_id
      )
    )
    |> Enum.into([])
  end

  defp handle_report(
         import_session_id,
         %ReportFile{source: "widiba", file_path: file_path, owner: owner}
       ) do
    IO.puts("handling widiba report with owner=#{owner}, file_path=#{file_path}")

    file_path
    |> Path.expand(__DIR__)
    |> Xlsxir.stream_list(0)
    |> Enum.map(fn xls_record ->
      xls_record
      |> Enum.filter(fn item -> item != nil end)
      |> Enum.into([])
    end)
    |> Enum.filter(&(Enum.count(&1) == 5))
    |> Enum.map(
      &Expense.parse_expense(
        &1,
        :widiba,
        owner
        |> String.downcase(),
        import_session_id
      )
    )
    |> Enum.into([])
  end
end
