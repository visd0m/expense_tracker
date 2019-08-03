# ExpenseTracker

Personal tool I use to map bank accounts reports and upload them to a google spreadsheet.

## Warning

**the project is a personal tool**

**it just handles the type of bank accounts I need, it is not thougth as a "all bank accounts" tool**

Handled bank accounts
- revolut
- sella
- widiba

## Highlight of the project

- The script is configurable using a json file `config/config.json`
```
{
  "spreadsheet_id": "11nvtF9XQOJIz0KSpJtGRmsIA0bks-VNJ3HoyrNcdBv4",
  "report_files": [
    {
      "file_path": "/Users/domenicovisconti/Desktop/export/Revolut-EUR-Statement-1 Jun 2019 to 31 Jul 2019.csv",
      "source": "revolut",
      "owner": "SARA"
    },
    {
      "file_path": "/Users/domenicovisconti/Desktop/export/Revolut-EUR-Statement-giu – lug 2019.csv",
      "source": "revolut",
      "owner": "DOMENICO"
    },
    {
      "file_path": "/Users/domenicovisconti/Desktop/export/ListaMovimentiConto.csv",
      "source": "sella",
      "owner": "DOMENICO"
    },
    {
      "file_path": "/Users/domenicovisconti/Desktop/export/I miei movimenti conto.xlsx",
      "source": "widiba",
      "owner": "DOMENICO"
    }
  ]
}

```
- csv and xls parsing using 
  - `{:csv, "~> 2.3"}`
  - `{:xlsxir, "~> 1.6"}`
- `{:goth, "~> 1.1"}` is used to authenticate `{:google_api_sheets, "~> 0.7.0"}` requests through oauth2.

## How to run

To run the script, log into iex loading the mix project
```
iex -S mix  
```

Parse report files, map them and upload them to google sheet using
```
ExpenseTracker.track 
```