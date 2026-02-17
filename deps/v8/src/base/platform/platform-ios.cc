// Copyright 2023 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "src/base/base-export.h"
#include "src/base/build_config.h"
#include <dlfcn.h>

// pthread_jit_write_protect_np is not declared in iOS SDK headers.
// Resolve it dynamically so this binary can still load on older runtimes.
using pthread_jit_write_protect_np_t = void (*)(int);

namespace v8::base {

#if V8_HAS_PTHREAD_JIT_WRITE_PROTECT && defined(V8_OS_IOS)
V8_BASE_EXPORT void SetJitWriteProtected(int enable) {
  static pthread_jit_write_protect_np_t fn =
      reinterpret_cast<pthread_jit_write_protect_np_t>(
          dlsym(RTLD_DEFAULT, "pthread_jit_write_protect_np"));
  if (fn != nullptr) fn(enable);
}
#endif

}  // namespace v8::base
