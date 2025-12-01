const opcodes = @import("z80_opcodes.zig");
const OpcodeHandler = *const fn () void;

var mainOpcodes: [256]OpcodeHandler = [_]*const fn () void{opcodes.op_unknown} ** 256;
//function created to load all of the opcodes functions into the opcode arrays/lookup table
pub fn initTables() void {
    for (0..256) |index| {
        mainOpcodes[index] = opcodes.op_unknown;
    }
    mainOpcodes[0x00] = opcodes.op_nop;
    mainOpcodes[0x01] = opcodes.op_ld_bc_nn;
    mainOpcodes[0x02] = opcodes.op_ld_a_bc_addr;
    mainOpcodes[0x03] = opcodes.op_inc_bc;
    mainOpcodes[0x04] = opcodes.op_inc_b;
    mainOpcodes[0x05] = opcodes.op_dec_b;
    mainOpcodes[0x06] = opcodes.op_ld_b_n;
    mainOpcodes[0x07] = opcodes.op_rlca;
    mainOpcodes[0x08] = opcodes.op_ex_af_af_shadow;
    mainOpcodes[0x09] = opcodes.op_add_hl_bc;
    mainOpcodes[0x0A] = opcodes.op_ld_a_bc_addr;
    mainOpcodes[0x0B] = opcodes.op_dec_bc;
    mainOpcodes[0x0C] = opcodes.op_inc_c;
    mainOpcodes[0x0D] = opcodes.op_dec_c;
    mainOpcodes[0x0E] = opcodes.op_ld_c_n;
    mainOpcodes[0x0F] = opcodes.op_rrca;

    mainOpcodes[0x10] = opcodes.op_djnz_d;
    mainOpcodes[0x11] = opcodes.op_ld_de_nn;
    mainOpcodes[0x12] = opcodes.op_ld_a_de_addr;
    mainOpcodes[0x13] = opcodes.op_inc_de;
    mainOpcodes[0x14] = opcodes.op_inc_d;
    mainOpcodes[0x15] = opcodes.op_dec_d;
    mainOpcodes[0x16] = opcodes.op_ld_d_n;
    mainOpcodes[0x17] = opcodes.rla;
    mainOpcodes[0x18] = opcodes.jr_d;
    mainOpcodes[0x19] = opcodes.op_add_hl_de;
    mainOpcodes[0x1A] = opcodes.op_ld_de_addr_a;
    mainOpcodes[0x1B] = opcodes.op_dec_de;
    mainOpcodes[0x1C] = opcodes.op_inc_e;
    mainOpcodes[0x1D] = opcodes.op_dec_e;
    mainOpcodes[0x1E] = opcodes.op_ld_e_n;
    mainOpcodes[0x1F] = opcodes.op_rra;

    mainOpcodes[0x20] = opcodes.op_jr_nz;
    mainOpcodes[0x21] = opcodes.op_ld_hl_nn;
    mainOpcodes[0x22] = opcodes.op_ld_nn_addr_hl;
    mainOpcodes[0x23] = opcodes.op_inc_hl;
    mainOpcodes[0x24] = opcodes.op_inc_h;
    mainOpcodes[0x25] = opcodes.op_dec_h;
    mainOpcodes[0x26] = opcodes.op_ld_h_n;
    mainOpcodes[0x27] = opcodes.op_daa;
    mainOpcodes[0x28] = opcodes.op_jr_z;
    mainOpcodes[0x29] = opcodes.op_add_hl_hl;
    mainOpcodes[0x2A] = opcodes.op_ld_hl_nn_addr;
    mainOpcodes[0x2B] = opcodes.op_dec_hl;
    mainOpcodes[0x2C] = opcodes.op_inc_l;
    mainOpcodes[0x2D] = opcodes.op_dec_l;
    mainOpcodes[0x2E] = opcodes.op_ld_l_n;
    mainOpcodes[0x2F] = opcodes.op_cpl;

    mainOpcodes[0x30] = opcodes.op_jr_nc;
    mainOpcodes[0x31] = opcodes.op_ld_sp_nn;
    mainOpcodes[0x32] = opcodes.op_ld_nn_addr_a;
    mainOpcodes[0x33] = opcodes.op_inc_sp;
    mainOpcodes[0x34] = opcodes.op_inc_hl_addr;
    mainOpcodes[0x35] = opcodes.op_dec_hl_addr;
    mainOpcodes[0x36] = opcodes.op_ld_hl_addr_n;
    mainOpcodes[0x38] = opcodes.op_scf;
    mainOpcodes[0x38] = opcodes.op_jr_c;
    mainOpcodes[0x39] = opcodes.op_add_hl_sp;
    mainOpcodes[0x3A] = opcodes.op_ld_a_nn_addr;
    mainOpcodes[0x3B] = opcodes.op_dec_sp;
    mainOpcodes[0x3C] = opcodes.op_inc_a;
    mainOpcodes[0x3D] = opcodes.op_dec_a;
    mainOpcodes[0x3E] = opcodes.op_ld_a_n;
    mainOpcodes[0x3F] = opcodes.op_ccf;


    //All the ld_reg_reg functions done here
    for(0x40..0x7F) |op| {
        mainOpcodes[op] = opcodes.decode_ld;
    }

    for(0x80..0x87) |op| {
        mainOpcodes[op] = opcodes.decode_add_a;
    }

    for(0x88..0x8F) |op| {
        mainOpcodes[op] = opcodes.decode_adc_a;
    }

    for(0x90..0x97) |op| {
        mainOpcodes[op] = opcodes.decode_sub_a;
    }

    for(0x98..0x9F) |op| {
        mainOpcodes[op] = opcodes.decode_sub_a;
    }
}
