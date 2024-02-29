load("@fbsource//xplat/executorch/build:runtime_wrapper.bzl", "runtime")

def define_common_targets():
    for aten in (True, False):
        aten_suffix = "_aten" if aten else ""

        runtime.cxx_library(
            name = "runner" + aten_suffix,
            srcs = [
                "runner.cpp",
            ],
            exported_headers = [
                "runner.h",
                "util.h",
            ],
            preprocessor_flags = [
                "-DUSE_ATEN_LIB",
            ] if aten else [],
            visibility = [
                "@EXECUTORCH_CLIENTS",
            ],
            exported_deps = [
                "//executorch/backends/xnnpack:xnnpack_backend",
                "//executorch/examples/models/llama2/sampler:sampler" + aten_suffix,
                "//executorch/examples/models/llama2/tokenizer:tokenizer",
                "//executorch/extension/evalue_util:print_evalue" + aten_suffix,
                "//executorch/extension/runner_util:managed_tensor" + aten_suffix,
                "//executorch/extension/module:module" + aten_suffix,
                "//executorch/kernels/quantized:generated_lib" + aten_suffix,
                "//executorch/kernels/portable:" + ("generated_lib_aten" if aten else "generated_lib_all_ops"),
                "//executorch/runtime/core/exec_aten:lib" + aten_suffix,
            ] + ([
                "//executorch/examples/models/llama2/custom_ops:custom_ops",
            ] if ((not aten) and (not runtime.is_oss)) else []),
            external_deps = [
                "libtorch",
            ] if aten else [],
        )
