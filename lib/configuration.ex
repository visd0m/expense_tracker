defmodule Configuration do
  @enforce_keys [:spreadsheet_id, :report_files]
  defstruct [:spreadsheet_id, :report_files]

  @type t :: %Configuration{
          spreadsheet_id: String.t(),
          report_files: [ReportFile.t()]
        }

  @spec load_configuration(String.t()) :: Configuration.t()
  def load_configuration(path) do
    Poison.decode!(File.read!(path),
      as: %Configuration{
        spreadsheet_id: "spreadsheet_id",
        report_files: [%ReportFile{file_path: "file_path", owner: "owner", source: "source"}]
      }
    )
  end
end
