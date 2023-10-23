# buck2 build --config build.type=debug examples/portable/executor_runner:executor_runner

python3 -m examples.portable.scripts.export_and_delegate
buck2 run --config build.type=debug examples/portable/executor_runner:executor_runner -- --model_path whole.pte

python3 -m examples.portable.scripts.export
buck2 run --config build.type=debug examples/portable/executor_runner:executor_runner -- --model_path add.pte

# # not work due to torch.dynamo
# python -m debugpy \
#     --listen 5678 --wait-for-client \
#     -m examples.portable.scripts.export_and_delegate

flatc --json --defaults-json --strict-json -o . schema/program.fbs \
    -- add.pte

python3 -m examples.portable.scripts.export --model_name="linear"
buck2 run --config build.type=debug examples/portable/executor_runner:executor_runner -- --model_path linear.pte
flatc --json --defaults-json --strict-json -o . schema/program.fbs \
    -- linear.pte
