# E-commerce Sales Analysis using Apache Hive (Docker)

Runs Apache Hive 4 in Docker, so **no Hadoop/Hive/Java installation is needed**. Only Docker is required.

## Run
1. Install and start **Docker Desktop** (Windows/macOS) or Docker Engine (Linux).
2. Open a terminal in this folder.
3. Windows: double-click or run `run.bat`   |   Linux/macOS/WSL: `./run.sh`

The script starts the container, waits for HiveServer2 (first start: 1-2 min plus image download),
runs `hql/01_create_tables.hql`, `02_analysis.hql`, `03_export.hql`, and saves the printed
results to `output/console_output.txt` (CSV summaries in `output/*_summary/`).

Take a screenshot of the terminal output for Section 9 of the report.

## Compare with expected answers (needs Python + pandas, optional)
    python scripts/verify_results.py     # expected numbers, computed independently
    python scripts/charts.py             # redraws figures/ (needs matplotlib)

## Useful commands
    docker logs hive4                                         # if startup fails
    docker exec -it hive4 beeline -u jdbc:hive2://localhost:10000/   # interactive HiveQL
    docker compose down                                       # stop and remove (resets tables)
HiveServer2 web UI: http://localhost:10002

## Folder
    data/raw/orders.csv       input (103 lines: 100 valid + 3 faulty rows)
    hql/                      the three HiveQL scripts
    scripts/                  data generator, pandas checks, charts
    report/                   project report (.docx and .pdf)
