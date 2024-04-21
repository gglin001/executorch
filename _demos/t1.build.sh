git submodule init
# skip vulkan
git submodule deinit backends/vulkan/third-party
# no `--recursive` for pytorchF
git submodule update --init --depth=1 third-party/pytorch
git submodule update --depth=1 --recursive

# ln -s $PWD $PWD/executorch
mkdir -p executorch
ln -s $PWD/backends executorch
ln -s $PWD/examples executorch
ln -s $PWD/exir executorch
ln -s $PWD/schema/program.fbs executorch/exir/_serialize
ln -s $PWD/schema/scalar_type.fbs executorch/exir/_serialize
ln -s $PWD/extension executorch
ln -s $PWD/schema executorch
ln -s $PWD/sdk executorch
ln -s $PWD/util executorch

# install buck2
python build/resolve_buck.py --cache_dir _demos
mkdir -p _demos/bin && mv -f _demos/buck2-* _demos/bin/buck2
chmod +x _demos/bin/buck2

# install flatc
bash build/install_flatc.sh

export EXECUTORCH_BUILD_CUSTOM_OPS_AOT=0
export BUCK2="$PWD/_demos/bin/buck2"
export PATH="$PWD/third-party/flatbuffers/cmake-out:$PWD/_demos/bin:${PATH}"
bash install_requirements.sh
# pip install -e .

# test env
buck2 cquery //examples/portable/executor_runner:executor_runner
python3 -m examples.portable.scripts.export --model_name="add"
buck2 run //examples/portable/executor_runner:executor_runner -- --model_path add.pte

###############################################################################
