// Copyright 2021 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "src/wasm/code-space-access.h"

#include "src/base/page-allocator.h"
#include "src/common/code-memory-access-inl.h"
#include "src/utils/allocation.h"

namespace v8::internal::wasm {

CodeSpaceWriteScope::CodeSpaceWriteScope()
    : rwx_write_scope_("For wasm::CodeSpaceWriteScope.") {
#if defined(V8_TARGET_OS_IOS) && !V8_HAS_PTHREAD_JIT_WRITE_PROTECT
  // On iOS device builds (no pthread_jit_write_protect), JIT pages are
  // allocated as RWX and stay that way. Toggling permissions via mprotect
  // is both unnecessary and racy — concurrent threads can SIGBUS when a
  // page is momentarily flipped to RX while another thread writes to it.
#else
  if (!UseMapAsJittableMemory()) {
    CHECK(ThreadIsolation::SetPermissionsOnAllJitPages(
        PageAllocator::Permission::kReadWriteExecute));
  }
#endif
}

CodeSpaceWriteScope::~CodeSpaceWriteScope() {
#if defined(V8_TARGET_OS_IOS) && !V8_HAS_PTHREAD_JIT_WRITE_PROTECT
  // Pages stay RWX — see constructor comment.
#else
  if (!UseMapAsJittableMemory()) {
    CHECK(ThreadIsolation::SetPermissionsOnAllJitPages(
        PageAllocator::Permission::kReadExecute));
  }
#endif
}

}  // namespace v8::internal::wasm
