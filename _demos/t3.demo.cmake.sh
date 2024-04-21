python -m examples.portable.scripts.export -m add
executor_runner --model_path add.pte
flatc --json --defaults-json --strict-json -o . schema/program.fbs \
    -- add.pte

# python -m examples.portable.scripts.export_and_delegate --option mv3
python -m examples.portable.scripts.export -m mv3
executor_runner --model_path mv3.pte

###############################################################################
