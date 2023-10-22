# https://pytorch.org/executorch/stable/getting-started-setup.html
# https://pytorch.org/executorch/stable/runtime-build-and-cross-compilation.html

ln -s $PWD $PWD/executorch
bash install_requirements.sh

# install buck2
wget https://github.com/facebook/buck2/releases/download/latest/buck2-x86_64-unknown-linux-gnu.zst
unzstd buck2-x86_64-unknown-linux-gnu.zst
chmod +x buck2-x86_64-unknown-linux-gnu
cp buck2-x86_64-unknown-linux-gnu /usr/local/bin/buck2

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
buck2 run //examples/portable/executor_runner:executor_runner
