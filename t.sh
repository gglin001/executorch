# https://pytorch.org/executorch/stable/getting-started-setup.html
# https://pytorch.org/executorch/stable/runtime-build-and-cross-compilation.html

git submodule init
git submodule update --recursive --init --depth=1

# ln -s $PWD $PWD/executorch
mkdir executorch
ln -s $PWD/backends executorch
ln -s $PWD/exir executorch
ln -s $PWD/schema executorch
ln -s $PWD/sdk executorch
ln -s $PWD/extension executorch
ln -s $PWD/bundled_program executorch

bash install_requirements.sh

# install buck2
# https://github.com/facebook/buck2/releases
wget https://github.com/facebook/buck2/releases/download/latest/buck2-x86_64-unknown-linux-gnu.zst -O buck2.zst
wget https://github.com/facebook/buck2/releases/download/latest/buck2-aarch64-unknown-linux-gnu.zst -O buck2.zst
wget https://github.com/facebook/buck2/releases/download/latest/buck2-aarch64-apple-darwin.zst -O buck2.zst
unzstd buck2.zst
chmod +x buck2
# cp buck2 /usr/local/bin/buck2
cp buck2 ~/.local/bin/buck2

# or built buck2 from source
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup install nightly-2023-07-10
cargo +nightly-2023-07-10 install --git https://github.com/facebook/buck2.git buck2

# append to  ~/.bashrc
# export PATH="/alleng/repos/executorch/third-party/flatbuffers/cmake-out:${PATH}"
# . "$HOME/.cargo/env"
# export PATH=$HOME/.cargo/bin:$PATH

# test env
buck2 cquery //examples/portable/executor_runner:executor_runner

python3 -m examples.portable.scripts.export --model_name="add"
buck2 run //examples/portable/executor_runner:executor_runner -- --model_path add.pte

# test cmake building
# build with vscode config `.vscode/settings.json`
./cmake-out/executor_runner --model_path add.pte

buck2 run examples/portable/executor_runner:executor_runner -- --model_path ./mv2.pte
buck2 run --config build.type=debug examples/portable/executor_runner:executor_runner -- --model_path add.pte
