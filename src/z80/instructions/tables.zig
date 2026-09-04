const main = @import("main.zig");
const cb = @import("cb.zig");
const s = @import("../internals/state.zig");
const OpcodeHandler = *const fn (*s.State) u8;

//how the fuck do i assign the cycles for each instruction, this is some bullshit
pub var mainOpcodes: [256]OpcodeHandler = [_]*const fn (*s.State) u8{main.op_unknown} ** 256;

//opcodes reached through the CB prefix (bit/rotate/shift instructions)
pub var cbOpcodes: [256]OpcodeHandler = [_]*const fn (*s.State) u8{main.op_unknown} ** 256;
//function created to load all of the main.functions into the opcode arrays/lookup table
pub fn initTables() void {
    mainOpcodes[0x00] = main.op_nop;
    mainOpcodes[0x01] = main.decode_ld_16reg_nn;
    mainOpcodes[0x02] = main.op_ld_bc_addr_a;
    mainOpcodes[0x03] = main.decode_inc_16reg;
    mainOpcodes[0x04] = main.decode_inc_8reg;
    mainOpcodes[0x05] = main.decode_dec_8reg;
    mainOpcodes[0x06] = main.decode_ld_reg_n;
    mainOpcodes[0x07] = main.op_rlca;
    mainOpcodes[0x08] = main.op_ex_af_af_shadow;
    mainOpcodes[0x09] = main.op_add_hl_bc;
    mainOpcodes[0x0A] = main.op_ld_a_bc_addr;
    mainOpcodes[0x0B] = main.decode_dec_16reg;
    mainOpcodes[0x0C] = main.decode_inc_8reg;
    mainOpcodes[0x0D] = main.decode_dec_8reg;
    mainOpcodes[0x0E] = main.decode_ld_reg_n;
    mainOpcodes[0x0F] = main.decode_rrca;

    mainOpcodes[0x10] = main.op_djnz_d;
    mainOpcodes[0x11] = main.decode_ld_16reg_nn;
    mainOpcodes[0x12] = main.op_ld_de_addr_a;
    mainOpcodes[0x13] = main.decode_inc_16reg;
    mainOpcodes[0x14] = main.decode_inc_8reg;
    mainOpcodes[0x15] = main.decode_dec_8reg;
    mainOpcodes[0x16] = main.decode_ld_reg_n;
    mainOpcodes[0x17] = main.decode_rla;
    mainOpcodes[0x18] = main.jr_d;
    mainOpcodes[0x19] = main.op_add_hl_de;
    mainOpcodes[0x1A] = main.op_ld_a_de_addr;
    mainOpcodes[0x1B] = main.decode_dec_16reg;
    mainOpcodes[0x1C] = main.decode_inc_8reg;
    mainOpcodes[0x1D] = main.decode_dec_8reg;
    mainOpcodes[0x1E] = main.decode_ld_reg_n;
    mainOpcodes[0x1F] = main.decode_rra;

    mainOpcodes[0x20] = main.op_jr_nz;
    mainOpcodes[0x21] = main.decode_ld_16reg_nn;
    mainOpcodes[0x22] = main.op_ld_nn_addr_hl;
    mainOpcodes[0x23] = main.decode_inc_16reg;
    mainOpcodes[0x24] = main.decode_inc_8reg;
    mainOpcodes[0x25] = main.decode_dec_8reg;
    mainOpcodes[0x26] = main.decode_ld_reg_n;
    mainOpcodes[0x27] = main.op_daa;
    mainOpcodes[0x28] = main.op_jr_z;
    mainOpcodes[0x29] = main.op_add_hl_hl;
    mainOpcodes[0x2A] = main.op_ld_hl_nn_addr;
    mainOpcodes[0x2B] = main.decode_dec_16reg;
    mainOpcodes[0x2C] = main.decode_inc_8reg;
    mainOpcodes[0x2D] = main.decode_dec_8reg;
    mainOpcodes[0x2E] = main.decode_ld_reg_n;
    mainOpcodes[0x2F] = main.op_cpl;

    mainOpcodes[0x30] = main.op_jr_nc;
    mainOpcodes[0x31] = main.decode_ld_16reg_nn;
    mainOpcodes[0x32] = main.op_ld_nn_addr_a;
    mainOpcodes[0x33] = main.decode_inc_16reg;
    mainOpcodes[0x34] = main.decode_inc_8reg;
    mainOpcodes[0x35] = main.decode_dec_8reg;
    mainOpcodes[0x36] = main.decode_ld_reg_n;
    mainOpcodes[0x37] = main.op_scf;
    mainOpcodes[0x38] = main.op_jr_c;
    mainOpcodes[0x39] = main.op_add_hl_sp;
    mainOpcodes[0x3A] = main.op_ld_a_nn_addr;
    mainOpcodes[0x3B] = main.decode_dec_16reg;
    mainOpcodes[0x3C] = main.decode_inc_8reg;
    mainOpcodes[0x3D] = main.decode_dec_8reg;
    mainOpcodes[0x3E] = main.decode_ld_reg_n;
    mainOpcodes[0x3F] = main.op_ccf;


    //All the ld_reg_reg functions done here
    for(0x40..0x80) |op| {
        mainOpcodes[op] = main.decode_ld;
    }

    mainOpcodes[0x76] = main.op_halt;

    for(0x80..0x88) |op| {
        mainOpcodes[op] = main.decode_add_a;
    }

    for(0x88..0x90) |op| {
        mainOpcodes[op] = main.decode_adc_a;
    }

    for(0x90..0x98) |op| {
        mainOpcodes[op] = main.decode_sub_a;
    }

    for(0x98..0xA0) |op| {
        mainOpcodes[op] = main.decode_sbc_a;
    }

    for(0xA0..0xA8) |op| {
        mainOpcodes[op] = main.decode_and_a;
    }

    for(0xA8..0xB0) |op| {
        mainOpcodes[op] = main.decode_xor_a;
    }

    for(0xB0..0xB8) |op| {
        mainOpcodes[op] = main.decode_or_a;
    }

    for(0xB8..0xC0) |op| {
        mainOpcodes[op] = main.decode_cp_a;
    }


    mainOpcodes[0xC0] = main.decode_ret_condition_nn;
    mainOpcodes[0xD0] = main.decode_ret_condition_nn;
    mainOpcodes[0xE0] = main.decode_ret_condition_nn;
    mainOpcodes[0xF0] = main.decode_ret_condition_nn;

    mainOpcodes[0xC1] = main.decode_pop_reg;
    mainOpcodes[0xD1] = main.decode_pop_reg;
    mainOpcodes[0xE1] = main.decode_pop_reg;
    mainOpcodes[0xF1] = main.decode_pop_reg;

    mainOpcodes[0xC2] = main.decode_jp_condition_nn;
    mainOpcodes[0xD2] = main.decode_jp_condition_nn;
    mainOpcodes[0xE2] = main.decode_jp_condition_nn;
    mainOpcodes[0xF2] = main.decode_jp_condition_nn;

    mainOpcodes[0xC3] = main.op_jp_nn;

    mainOpcodes[0xC4] = main.decode_call_condition_nn;
    mainOpcodes[0xD4] = main.decode_call_condition_nn;
    mainOpcodes[0xE4] = main.decode_call_condition_nn;
    mainOpcodes[0xF4] = main.decode_call_condition_nn;

    mainOpcodes[0xC5] = main.decode_push_reg;
    mainOpcodes[0xD5] = main.decode_push_reg;
    mainOpcodes[0xE5] = main.decode_push_reg;
    mainOpcodes[0xF5] = main.decode_push_reg;

    mainOpcodes[0xC6] = main.decode_add_a_n;
    mainOpcodes[0xD6] = main.decode_sub_n;
    mainOpcodes[0xE6] = main.op_and_n;
    mainOpcodes[0xF6] = main.op_or_n;

    mainOpcodes[0xC7] = main.decode_rst_value_h;
    mainOpcodes[0xD7] = main.decode_rst_value_h;
    mainOpcodes[0xE7] = main.decode_rst_value_h;
    mainOpcodes[0xF7] = main.decode_rst_value_h;

    mainOpcodes[0xC8] = main.decode_ret_condition_nn;
    mainOpcodes[0xD8] = main.decode_ret_condition_nn;
    mainOpcodes[0xE8] = main.decode_ret_condition_nn;
    mainOpcodes[0xF8] = main.decode_ret_condition_nn;

    mainOpcodes[0xC9] = main.op_ret;
    mainOpcodes[0xE9] = main.op_jp_hl;
    mainOpcodes[0xF9] = main.op_ld_sp_hl;

    mainOpcodes[0xCA] = main.decode_jp_condition_nn;
    mainOpcodes[0xDA] = main.decode_jp_condition_nn;
    mainOpcodes[0xEA] = main.decode_jp_condition_nn;
    mainOpcodes[0xFA] = main.decode_jp_condition_nn;

    mainOpcodes[0xCC] = main.decode_call_condition_nn;
    mainOpcodes[0xDC] = main.decode_call_condition_nn;
    mainOpcodes[0xEC] = main.decode_call_condition_nn;
    mainOpcodes[0xFC] = main.decode_call_condition_nn;

    mainOpcodes[0xCD] = main.op_call_nn;

    mainOpcodes[0xCE] = main.op_adc_a_n;
    mainOpcodes[0xDE] = main.op_sbc_a_n;
    mainOpcodes[0xEE] = main.op_xor_n;
    mainOpcodes[0xFE] = main.op_cp_n;

    mainOpcodes[0xCF] = main.decode_rst_value_h;
    mainOpcodes[0xDF] = main.decode_rst_value_h;
    mainOpcodes[0xEF] = main.decode_rst_value_h;
    mainOpcodes[0xFF] = main.decode_rst_value_h;

    mainOpcodes[0xE3] = main.op_ex_sp_addr_hl;
    mainOpcodes[0xEB] = main.op_ex_de_hl;


    //CB-prefixed opcodes: each rotate/shift operation covers a fixed block of 8 opcodes,
    //one per register (B, C, D, E, H, L, (HL), A)
    for(0x00..0x08) |op| {
        cbOpcodes[op] = cb.decode_rlc;
    }

    for(0x08..0x10) |op| {
        cbOpcodes[op] = cb.decode_rrc;
    }

    for(0x10..0x18) |op| {
        cbOpcodes[op] = cb.decode_rl;
    }

    for(0x18..0x20) |op| {
        cbOpcodes[op] = cb.decode_rr;
    }

    for(0x20..0x28) |op| {
        cbOpcodes[op] = cb.decode_sla;
    }

    for(0x28..0x30) |op| {
        cbOpcodes[op] = cb.decode_sra;
    }
}
