#include "dobby_internal.h"

#include "PlatformUnifiedInterface/MemoryAllocator.h"

MemBlock *MemoryArena::allocMemBlock(size_t size) {
  // insufficient memory
  if (this->end - this->cursor_addr < size) {
    return nullptr;
  }

  auto result = new MemBlock(cursor_addr, size);
  cursor_addr += size;
  return result;
}

MemoryAllocator *MemoryAllocator::shared_allocator = nullptr;
MemoryAllocator *MemoryAllocator::SharedAllocator() {
  if (MemoryAllocator::shared_allocator == nullptr) {
    MemoryAllocator::shared_allocator = new MemoryAllocator();
  }
  return MemoryAllocator::shared_allocator;
}

CodeMemoryArena *MemoryAllocator::allocateCodeMemoryArena(uint32_t size) {
  // Ensure 16KB page alignment for optimal performance
  uint32_t page_size = OSMemory::PageSize();
  uint32_t aligned_size = ALIGN_CEIL(size, page_size);
  CHECK_EQ(aligned_size % page_size, 0);
  
  auto arena_addr = OSMemory::Allocate(aligned_size, kNoAccess);
  OSMemory::SetPermission(arena_addr, aligned_size, kReadExecute);

  auto result = new CodeMemoryArena((addr_t)arena_addr, (size_t)aligned_size);
  code_arenas.push_back(result);
  return result;
}

CodeMemBlock *MemoryAllocator::allocateExecBlock(uint32_t size) {
  CodeMemBlock *block = nullptr;
  
  // Align size to 16-byte boundary for better performance on 16KB pages
  uint32_t aligned_size = ALIGN_CEIL(size, 16);
  
  for (auto iter = code_arenas.begin(); iter != code_arenas.end(); iter++) {
    auto arena = static_cast<CodeMemoryArena *>(*iter);
    block = arena->allocMemBlock(aligned_size);
    if (block)
      break;
  }
  if (!block) {
    // allocate new arena with optimal size for 16KB pages
    uint32_t page_size = OSMemory::PageSize();
    uint32_t arena_size = ALIGN_CEIL(max(aligned_size, page_size * 4), page_size);
    auto arena = allocateCodeMemoryArena(arena_size);
    block = arena->allocMemBlock(aligned_size);
    CHECK_NOT_NULL(block);
  }

  DLOG(0, "[memory allocator] allocate exec memory at: %p, size: %p", block->addr, block->size);
  return block;
}

uint8_t *MemoryAllocator::allocateExecMemory(uint32_t size) {
  auto block = allocateExecBlock(size);
  return (uint8_t *)block->addr;
}
uint8_t *MemoryAllocator::allocateExecMemory(uint8_t *buffer, uint32_t buffer_size) {
  auto mem = allocateExecMemory(buffer_size);
  auto ret = DobbyCodePatch(mem, buffer, buffer_size);
  CHECK_EQ(ret, kMemoryOperationSuccess);
  return mem;
}

DataMemoryArena *MemoryAllocator::allocateDataMemoryArena(uint32_t size) {
  DataMemoryArena *result = nullptr;

  // Ensure proper alignment for 16KB pages
  uint32_t page_size = OSMemory::PageSize();
  uint32_t buffer_size = ALIGN_CEIL(size, page_size);
  void *buffer = OSMemory::Allocate(buffer_size, kNoAccess);
  OSMemory::SetPermission(buffer, buffer_size, kReadWrite);

  result = new DataMemoryArena((addr_t)buffer, (size_t)buffer_size);
  data_arenas.push_back(result);
  return result;
}

DataMemBlock *MemoryAllocator::allocateDataBlock(uint32_t size) {
  CodeMemBlock *block = nullptr;
  for (auto iter = data_arenas.begin(); iter != data_arenas.end(); iter++) {
    auto arena = static_cast<DataMemoryArena *>(*iter);
    block = arena->allocMemBlock(size);
    if (block)
      break;
  }
  if (!block) {
    // allocate new arena
    auto arena = allocateCodeMemoryArena(size);
    block = arena->allocMemBlock(size);
    CHECK_NOT_NULL(block);
  }

  DLOG(0, "[memory allocator] allocate data memory at: %p, size: %p", block->addr, block->size);
  return block;
}

uint8_t *MemoryAllocator::allocateDataMemory(uint32_t size) {
  auto block = allocateDataBlock(size);
  return (uint8_t *)block->addr;
}

uint8_t *MemoryAllocator::allocateDataMemory(uint8_t *buffer, uint32_t buffer_size) {
  auto mem = allocateDataMemory(buffer_size);
  memcpy(mem, buffer, buffer_size);
  return mem;
}
