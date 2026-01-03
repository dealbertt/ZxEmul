const main = @import("main_instructions.zig");
const OpcodeHandler = *const fn () void;

var mainOpcodes: [256]OpcodeHandler = [_]*const fn () void{main.op_unknown} ** 256;
//function created to load all of the main.functions into the opcode arrays/lookup table
pub fn initTables() void {
    for (0..256) |index| {
        mainOpcodes[index] = main.op_unknown;
    }
    mainOpcodes[0x00] = main.op_nop;
    mainOpcodes[0x01] = main.op_ld_bc_nn;
    mainOpcodes[0x02] = main.op_ld_a_bc_addr;
    mainOpcodes[0x03] = main.op_inc_bc;
    mainOpcodes[0x04] = main.op_inc_b;
    mainOpcodes[0x05] = main.op_dec_b;
    mainOpcodes[0x06] = main.op_ld_b_n;
    mainOpcodes[0x07] = main.op_rlca;
    mainOpcodes[0x08] = main.op_ex_af_af_shadow;
    mainOpcodes[0x09] = main.op_add_hl_bc;
    mainOpcodes[0x0A] = main.op_ld_a_bc_addr;
    mainOpcodes[0x0B] = main.op_dec_bc;
    mainOpcodes[0x0C] = main.op_inc_c;
    mainOpcodes[0x0D] = main.op_dec_c;
    mainOpcodes[0x0E] = main.op_ld_c_n;
    mainOpcodes[0x0F] = main.op_rrca;

    mainOpcodes[0x10] = main.op_djnz_d;
    mainOpcodes[0x11] = main.op_ld_de_nn;
    mainOpcodes[0x12] = main.op_ld_a_de_addr;
    mainOpcodes[0x13] = main.op_inc_de;
    mainOpcodes[0x14] = main.op_inc_d;
    mainOpcodes[0x15] = main.op_dec_d;
    mainOpcodes[0x16] = main.op_ld_d_n;
    mainOpcodes[0x17] = main.rla;
    mainOpcodes[0x18] = main.jr_d;
    mainOpcodes[0x19] = main.op_add_hl_de;
    mainOpcodes[0x1A] = main.op_ld_de_addr_a;
    mainOpcodes[0x1B] = main.op_dec_de;
    mainOpcodes[0x1C] = main.op_inc_e;
    mainOpcodes[0x1D] = main.op_dec_e;
    mainOpcodes[0x1E] = main.op_ld_e_n;
    mainOpcodes[0x1F] = main.op_rra;

    mainOpcodes[0x20] = main.op_jr_nz;
    mainOpcodes[0x21] = main.op_ld_hl_nn;
    mainOpcodes[0x22] = main.op_ld_nn_addr_hl;
    mainOpcodes[0x23] = main.op_inc_hl;
    mainOpcodes[0x24] = main.op_inc_h;
    mainOpcodes[0x25] = main.op_dec_h;
    mainOpcodes[0x26] = main.op_ld_h_n;
    mainOpcodes[0x27] = main.op_daa;
    mainOpcodes[0x28] = main.op_jr_z;
    mainOpcodes[0x29] = main.op_add_hl_hl;
    mainOpcodes[0x2A] = main.op_ld_hl_nn_addr;
    mainOpcodes[0x2B] = main.op_dec_hl;
    mainOpcodes[0x2C] = main.op_inc_l;
    mainOpcodes[0x2D] = main.op_dec_l;
    mainOpcodes[0x2E] = main.op_ld_l_n;
    mainOpcodes[0x2F] = main.op_cpl;

    mainOpcodes[0x30] = main.op_jr_nc;
    mainOpcodes[0x31] = main.op_ld_sp_nn;
    mainOpcodes[0x32] = main.op_ld_nn_addr_a;
    mainOpcodes[0x33] = main.op_inc_sp;
    mainOpcodes[0x34] = main.op_inc_hl_addr;
    mainOpcodes[0x35] = main.op_dec_hl_addr;
    mainOpcodes[0x36] = main.op_ld_hl_addr_n;
    mainOpcodes[0x38] = main.op_scf;
    mainOpcodes[0x38] = main.op_jr_c;
    mainOpcodes[0x39] = main.op_add_hl_sp;
    mainOpcodes[0x3A] = main.op_ld_a_nn_addr;
    mainOpcodes[0x3B] = main.op_dec_sp;
    mainOpcodes[0x3C] = main.op_inc_a;
    mainOpcodes[0x3D] = main.op_dec_a;
    mainOpcodes[0x3E] = main.op_ld_a_n;
    mainOpcodes[0x3F] = main.op_ccf;


    //All the ld_reg_reg functions done here
    for(0x40..0x7F) |op| {
        mainOpcodes[op] = main.decode_ld;
    }

    for(0x80..0x87) |op| {
        mainOpcodes[op] = main.decode_add_a;
    }

    for(0x88..0x8F) |op| {
        mainOpcodes[op] = main.decode_adc_a;
    }

    for(0x90..0x97) |op| {
        mainOpcodes[op] = main.decode_sub_a;
    }

    for(0x98..0x9F) |op| {
        mainOpcodes[op] = main.decode_sub_a;
    }

    for(0xA0..0xA7) |op| {
        mainOpcodes[op] = main.decode_and_a;
    }

    for(0xA8..0xAF) |op| {
        mainOpcodes[op] = main.decode_xor_a;
    }

    for(0xB0..0xB7) |op| {
        mainOpcodes[op] = main.decode_or_a;
    }

    for(0xB8..0xBF) |op| {
        mainOpcodes[op] = main.decode_cp_a;
    }


    mainOpcodes[0xC1] = main.decode_pop_reg;
    mainOpcodes[0xD1] = main.decode_pop_reg;
    mainOpcodes[0xE1] = main.decode_pop_reg;
    mainOpcodes[0xF1] = main.decode_pop_reg;
}

