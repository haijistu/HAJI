#include <common.h>

extern "C" void flash_read(int32_t addr, int32_t *data) {
  addr &= FLASH_SIZE - 1;
  addr &= 0xfffffffc;
  *data = flash[addr + 3] | (flash[addr+2] << 8) | (flash[addr+1] << 16) | (flash[addr] << 24);
  // printf("read 0x%08x: 0x%08x\n", addr, *data);
}

extern "C" void mrom_read(int32_t addr, int32_t *data) { 
  assert(0);
}

extern "C" void dram_read(int32_t addr, int32_t *data) {
  addr &= DRAM_SIZE - 1;
  *data = dram[addr + 3] | (dram[addr+2] << 8) | (dram[addr+1] << 16) | (dram[addr] << 24);
  // assert(0);
}

extern "C" void dram_write(int32_t addr, int32_t data, int32_t len) {
  // printf("write 0x%08x: 0x%08x, len: %d\n", addr, data, len);
  for(int i=0;i<len;i++) {
    dram[addr + (len - i - 1)] = (data >> (i*8)) & 0xff;
  }
}

extern "C" void sdram_read(int32_t row, int32_t bank, int32_t col, int32_t *data) {
  *data = sdram[bank][row][col];
  // printf("sdram read: 0x%04x col: 0x%x\n", *data, col);
}

extern "C" void sdram_write(int32_t row, int32_t bank, int32_t col, int32_t mask, int32_t data) {
  uint16_t temp = sdram[bank][row][col];
  switch (mask & 0b11) {
    case 0x0: sdram[bank][row][col] = data & 0xffff; break;
    case 0x1: sdram[bank][row][col] = (data & 0xff00) | (temp & 0xff); break;
    case 0x2: sdram[bank][row][col] = (data & 0x00ff) | (temp & 0xff00); break;
    default: break;
  }
  // printf("write: 0x%04x col: 0x%08x\n", sdram[bank][row][col], col);
}