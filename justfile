# Format all Typst files with 80-column prose wrapping, matching the editor settings.
fmt:
    typstyle --inplace --line-width 80 --indent-width 2 --wrap-text=fill .

# Check Typst formatting without changing files.
fmt-check:
    typstyle --check --line-width 80 --indent-width 2 --wrap-text=fill .
