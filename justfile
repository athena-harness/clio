# Format all Typst files using Tinymist's default formatting settings.
fmt:
    typstyle --inplace --line-width 120 --indent-width 2 --wrap-text=none .

# Check Typst formatting without changing files.
fmt-check:
    typstyle --check --line-width 120 --indent-width 2 --wrap-text=none .
