python -m examples.portable.scripts.export_and_delegate --option whole
buck2 run --config build.type=debug examples/portable/executor_runner:executor_runner -- --model_path whole.pte

python -m examples.portable.scripts.export -m add
buck2 run --config build.type=debug examples/portable/executor_runner:executor_runner -- --model_path add.pte
flatc --json --defaults-json --strict-json -o . schema/program.fbs \
    -- add.pte

python -m examples.portable.scripts.export --model_name="linear"
buck2 run --config build.type=debug examples/portable/executor_runner:executor_runner -- --model_path linear.pte
flatc --json --defaults-json --strict-json -o . schema/program.fbs \
    -- linear.pteF

###############################################################################

# # not work due to torch.dynamo
# python -m debugpy \
#     --listen 5678 --wait-for-client \
#     -m examples.portable.scripts.export_and_delegate

###############################################################################
