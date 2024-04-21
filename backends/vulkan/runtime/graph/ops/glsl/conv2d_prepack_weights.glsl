/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#version 450 core

#define PRECISION ${PRECISION}

#define BUF_T ${buffer_scalar_type(DTYPE)}
#define VEC4_T ${texel_type(DTYPE)}
#define SCALAR_T ${texel_component_type(DTYPE)}

#include "indexing_utils.h"

$if DTYPE == "half":
  #extension GL_EXT_shader_16bit_storage : require

layout(std430) buffer;

layout(set = 0, binding = 0, ${IMAGE_FORMAT[DTYPE]}) uniform PRECISION restrict writeonly ${IMAGE_T[2][DTYPE]} image_out;
layout(set = 0, binding = 1) buffer  PRECISION restrict readonly Buffer {
  BUF_T buffer_in[];
};

// Corresponds to {1,4,9,24} in the example below.
layout(set = 0, binding = 2) uniform PRECISION restrict Sizes {
  ivec4 sizes;
};

// Corresponds to {3,3,7,10} in the example below.
layout(set = 0, binding = 3) uniform PRECISION restrict OriginalSizes {
  ivec4 original_sizes;
};

// Corresponds to {8,12} in the example below.
layout(set = 0, binding = 4) uniform PRECISION restrict PaddedSizes {
  ivec2 padded_sizes;
};

layout(local_size_x_id = 0, local_size_y_id = 1, local_size_z_id = 2) in;

layout(constant_id = 3) const int packed_dim = C_DIM;

/*
 * Computes special prepacking for a 2D convolution. Each shader invocation
 * calculates the input buffer location to read into the desired texel. This
 * packing was originally developed on CPU and that approach is described in the
 * rest of this comment. Refer to the code-level comments, for how we translate
 * it to GPU by reversing the steps.
 *
 * Consider an example weight tensor of size {10,7,3,3}. The following
 * transformations will be applied.
 *
 * 1. Pad the N and C dims so that both are a multiple of 4. In this case, 2
 * batches and 1 channel of padding are added, producing a tensor of size
 * {12,8,3,3}.
 *      at::pad(x, {0,0,0,0,0,1,0,2}, "constant", 0);
 *
 * 2. Split the tensor along the C dim so that each split has 4 channels.
 *      x.reshape({12,2,4,3,3});
 *
 * 3. For each split, "fold" the C dim into the W dim. Suppose the first rows
 * at H=0 of the split have values
 *    0,1,2 | 10,11,12 | 20,21,22 | 30,31,32
 *
 * where | denotes a channel boundary. Then, the goal is to combine those rows
 * into one row with the values
 *    0, 10, 20, 30, 1, 11, 21, 31, 2, 12, 22, 32
 *
 *      x.permute({0,1,3,4,2}).reshape({12,2,3,12});
 *
 * 4. Stack the splits belonging to the same batch horizontally by swapping the
 * C and H dims.
 *      x.permute({0,2,1,3}).reshape({12,3,24});
 *
 * 5. Repeat a similar process to "fold" the N dim into the C dim. Split along
 * the N dim so that each split has 4 batches.
 *      x.reshape({3,4,3,24});
 *
 * 6. Stack the batches on each other vertically by swapping the N and C dims.
 *      x.permute({1,0,2,3}).reshape({4,9,24});
 */
void main() {
  const ivec3 pos = ivec3(gl_GlobalInvocationID);
  const ivec4 idx = to_tensor_idx(pos, sizes, packed_dim);

  if (any(greaterThanEqual(idx, sizes))) {
    return;
  }

  // As in usual staging shaders, map from GPU texel position to normal CPU
  // buffer indices: (24,9) -> (4,9,24)
  const ivec4 p0 = get_texel_nchw_buffer_ixs(idx, sizes, packed_dim);

  // Re-map the normal CPU buffer indices to special indices, through a series
  // of mappings: reshape is a no-op to the underlying indices, so we only map
  // for pad and permute.
  const int Np = padded_sizes.y;
  const int Cp = padded_sizes.x;
  const int N = original_sizes.w;
  const int C = original_sizes.z;
  const int H = original_sizes.y;
  const int W = original_sizes.x;

  // Undo step 6 premute: (4,3,3,24) -> (3,4,3,24)
  // Undo step 4 permute: (12,3,2,12) -> (12,2,3,12)
  // Undo step 3 permute, part 1: (12,2,3h,3w,4) -> (12,2,3h,4,3w)
  // Undo step 3 permute, part 2: (12,2,3h,4,3w) -> (12,2,4,3h,3w)
  const ivec4 p1 = swap_adj_dims(p0, 4, (Np / 4), (H * Cp * W));
  const ivec4 p2 = swap_adj_dims(p1, H, (Cp / 4), (W * 4));
  const ivec4 p3 = swap_adj_dims(p2, W, 4, 1);
  const ivec4 p4 = swap_adj_dims(p3, H, 4, W);

  // Undo step 1 pad: (12,8,3,3) -> (10,7,3,3)
  // For values in the padded region, write zero instead of buffer data.
  const ivec4 c = p4 % (Cp * H * W) / (H * W);
  const ivec4 n = p4 / (Cp * H * W);
  const ivec4 p5 = p4 - n * (Cp - C) * H * W;
  const ivec4 mask = ivec4(greaterThanEqual(c, ivec4(C))) |
      ivec4(greaterThanEqual(n, ivec4(N)));

  VEC4_T texel = VEC4_T(0);
  if (mask.x == 0) {
    texel.x = SCALAR_T(buffer_in[p5.x]);
  }
  if (mask.y == 0) {
    texel.y = SCALAR_T(buffer_in[p5.y]);
  }
  if (mask.z == 0) {
    texel.z = SCALAR_T(buffer_in[p5.z]);
  }
  if (mask.w == 0) {
    texel.w = SCALAR_T(buffer_in[p5.w]);
  }

  imageStore(image_out, pos.xy, texel);
}
