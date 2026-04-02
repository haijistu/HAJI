#include <common.h>

void npctrap() {
  // word_t a0 = regs(10);
  word_t a0 = 0;
  if(a0 == 0) {
    printf(ANSI_FMT("HIT GOOD TRAP\n", ANSI_FG_GREEN));
    npc_state = NPC_GOODTRAP;
  }
  else {
    printf(ANSI_FMT("HIT BAD TRAP\n", ANSI_FG_RED));
    npc_state = NPC_BADTRAP;
  }
}

bool itrace_flag = true;

void tick() {
  top->clock = 1; top->eval();
#ifdef CONFIG_WAVEFORM
  tfp->dump(contextp->time());
  contextp->timeInc(1);
#endif

  top->clock = 0; top->eval();
#ifdef CONFIG_WAVEFORM
  tfp->dump(contextp->time());
  contextp->timeInc(1);
#endif
#ifdef CONFIG_BOARD
  nvboard_update();
#endif
}

void exec_once() {
  while(npc_ifu_state == 0) tick();
  // 取指令
  bool retire_flag = false;
  if(!retire_flag) {
    tick();
    if(retire_valid_0 == 1) {
      retire_flag = true;
      if(itrace_flag) {
        inst_display(retire_pc_0, retire_inst_0);
      }
      if(retire_inst_0 == 0x00100073) {
        npctrap();
      }
    }
    
    if(retire_valid_1 == 1) {
      retire_flag = true;
      if(itrace_flag) {
        inst_display(retire_pc_1, retire_inst_1);
      }
      if(retire_inst_1 == 0x00100073) {
        npctrap();
      }
    }
  }
}

void cpu_exec(uint64_t n) {
  switch (npc_state) {
    case NPC_BADTRAP: case NPC_ABORT: case NPC_GOODTRAP: case NPC_QUIT:
      printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
      return;
    default: npc_state = NPC_RUNNING;
  }
  while(n--) {
    // word_t cur_pc = npc_pc;
    exec_once();
    // printf("0x%08x\n", npc_pc);
    // difftest_step(npc_pc, cur_pc);
    if(npc_state != NPC_RUNNING) break;
  }

  if(npc_state == NPC_RUNNING) npc_state = NPC_STOP;
}
