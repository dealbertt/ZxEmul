const s = @import("../internals/state.zig");
const h = @import("helpers.zig");
const mem = @import("../internals/memory.zig");
const tables = @import("tables.zig");
const cb = @import("cb.zig");

//DD (IX) and FD (IY) prefixed instructions.
//the prefix byte is the only thing that tells IX and IY apart - the opcode after it is the same
//for both - so every handler here is generic over a comptime base and gets instantiated twice
//when the tables are filled: once with .IX for ddOpcodes and once with .IY for fdOpcodes.
//each generic function returns the concrete handler that goes into the table.

const OpcodeHandler = *const fn (*s.State) u8;

fn indexedPair(r: h.Reg16Bit, base: h.IndexBase) h.Reg16Bit {
    //the way the decoding works, IX and IY are not identified, so they would all register as HL, thats why if r != from HL, its not one of those 3
    if(r !=  .HL) return r;
    return switch (base) {
        .HL => .HL,
        .IX => .IX,
        .IY => .IY,
    };
}

//the register (IX or IY) that takes the place of HL for this prefix
fn indexRegister(state: *s.State, comptime base: h.IndexBase) *u16 {
    return h.get16BitRegister(indexedPair(.HL, base), state);
}

//the signed displacement d of (IX+d)/(IY+d), which always comes right after the opcode
fn fetchDisplacement(state: *s.State) i8 {
    return @bitCast(mem.read8(state, &state.pc));
}

//Opcode 09, 19, 29, 39 (ADD IX,rr): rr is BC, DE, IX itself or SP
pub fn decode_add_index_rr(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            const src: h.Reg16Bit = @enumFromInt(@as(u8, @intCast((state.opcode >> 4) & 0b11)));
            const value = h.get16BitRegister(indexedPair(src, base), state).*;
            const index = indexRegister(state, base);

            index.* = h.add_16bitRegs(index.*, value, state);
            return 15;
        }
    }.handler;
}

//Opcode 21
pub fn op_ld_index_nn(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            indexRegister(state, base).* = mem.read16(state, &state.pc);
            return 14;
        }
    }.handler;
}

//Opcode 22
pub fn op_ld_nn_addr_index(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            const nn = mem.read16(state, &state.pc);
            const index = indexRegister(state, base).*;

            mem.write8(state, nn, @truncate(index));
            mem.write8(state, nn +% 1, @truncate(index >> 8));
            return 20;
        }
    }.handler;
}

//Opcode 23
pub fn op_inc_index(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            //INC IX affects no flags
            indexRegister(state, base).* +%= 1;
            return 10;
        }
    }.handler;
}

//Opcode 2A
pub fn op_ld_index_nn_addr(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            const nn = mem.read16(state, &state.pc);
            const lo = state.bus.read_memory(nn);
            const hi = state.bus.read_memory(nn +% 1);

            indexRegister(state, base).* = @as(u16, hi) << 8 | lo;
            return 20;
        }
    }.handler;
}

//Opcode 2B
pub fn op_dec_index(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            //DEC IX affects no flags
            indexRegister(state, base).* -%= 1;
            return 10;
        }
    }.handler;
}

//Opcode 34
pub fn op_inc_index_addr(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            const d = fetchDisplacement(state);
            h.inc_8bitReg(h.getRegister(.HL, state, base, d), state);
            return 23;
        }
    }.handler;
}

//Opcode 35
pub fn op_dec_index_addr(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            const d = fetchDisplacement(state);
            h.dec_8bitReg(h.getRegister(.HL, state, base, d), state);
            return 23;
        }
    }.handler;
}

//Opcode 36 (LD (IX+d),n): encoded as DD 36 d n, the displacement comes before the value
pub fn op_ld_index_addr_n(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            const d = fetchDisplacement(state);
            const value = mem.read8(state, &state.pc);

            h.setRegisterValue(.HL, value, state, base, d);
            return 19;
        }
    }.handler;
}

//Opcode 46, 4E, 56, 5E, 66, 6E, 7E (LD r,(IX+d))
//only the memory operand is indexed: H and L here are still the plain H and L registers
pub fn decode_ld_reg_index_addr(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            const dst: h.Register = @enumFromInt((state.opcode >> 3) & 0b111);
            const d = fetchDisplacement(state);

            const value = h.getRegisterValue(.HL, state, base, d);
            h.setRegisterValue(dst, value, state, .HL, 0);
            return 19;
        }
    }.handler;
}

//Opcode 70-75, 77 (LD (IX+d),r)
//only the memory operand is indexed: H and L here are still the plain H and L registers
pub fn decode_ld_index_addr_reg(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            const src: h.Register = @enumFromInt(state.opcode & 0b111);
            const d = fetchDisplacement(state);

            const value = h.getRegisterValue(src, state, .HL, 0);
            h.setRegisterValue(.HL, value, state, base, d);
            return 19;
        }
    }.handler;
}

//Opcode 86, 8E, 96, 9E, A6, AE, B6, BE (ADD/ADC/SUB/SBC/AND/XOR/OR/CP A,(IX+d))
//bits 3-5 of the opcode select the operation, in the same order as the unprefixed 80-BF block
pub fn decode_alu_index_addr(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            const d = fetchDisplacement(state);
            const value = h.getRegisterValue(.HL, state, base, d);
            const a = &state.af.bytes.hi;

            switch((state.opcode >> 3) & 0b111){
                0 => a.* = h.add_a_value(value, state),
                1 => a.* = h.adc_a_value(value, state),
                2 => a.* = h.sub_a_value(value, state),
                3 => a.* = h.sbc_a_value(value, state),
                4 => a.* = h.decode_binary_operation(value, .And, state),
                5 => a.* = h.decode_binary_operation(value, .Xor, state),
                6 => a.* = h.decode_binary_operation(value, .Or, state),
                //CP: like SUB, but the result is discarded and A is left unchanged
                7 => _ = h.sub_a_value(value, state),
                else => unreachable,
            }
            return 19;
        }
    }.handler;
}

//Opcode E1
pub fn op_pop_index(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            indexRegister(state, base).* = h.pop16BitValue(state);
            return 14;
        }
    }.handler;
}

//Opcode E3
pub fn op_ex_sp_addr_index(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            const index = indexRegister(state, base);
            const lo = state.bus.read_memory(state.sp);
            const hi = state.bus.read_memory(state.sp +% 1);

            mem.write8(state, state.sp, @truncate(index.*));
            mem.write8(state, state.sp +% 1, @truncate(index.* >> 8));

            index.* = @as(u16, hi) << 8 | lo;
            return 23;
        }
    }.handler;
}

//Opcode E5
pub fn op_push_index(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            h.push16BitValue(indexRegister(state, base).*, state);
            return 15;
        }
    }.handler;
}

//Opcode E9 (JP (IX)): jumps to the address held in IX, there is no memory read despite the brackets
pub fn op_jp_index(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            state.pc = indexRegister(state, base).*;
            return 8;
        }
    }.handler;
}

//Opcode F9
pub fn op_ld_sp_index(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            state.sp = indexRegister(state, base).*;
            return 10;
        }
    }.handler;
}

//undocumented DD/FD opcodes that don't touch HL: the prefix is ignored and the unprefixed
//instruction runs as normal, with the prefix fetch adding 4 T-states.
//not generic over IX/IY, since the index register plays no part.
//known gap: the ones that use H or L (INC H, LD A,L...) really act on the high/low half of IX/IY
//(the undocumented IXH/IXL registers), but here they still act on H and L
pub fn op_ignore_prefix(state: *s.State) u8 {
    switch(state.opcode){
        //another prefix right after this one: this prefix alone acts as a 4 T-state NOP and the
        //new one has to be decoded from scratch, so step back and let the next cycle fetch it
        0xDD, 0xFD, 0xED => {
            state.pc -%= 1;
            return 4;
        },
        else => return tables.mainOpcodes[state.opcode](state) + 4,
    }
}

//Opcode CB (DDCB/FDCB): the rotate/shift/BIT/RES/SET group, always on (IX+d).
//encoded as DD CB d op: unlike every other indexed instruction, the displacement comes
//BEFORE the byte that says which operation to run.
//bits 7-6 of op pick the group, bits 5-3 the rotate/shift or the bit number.
//bits 2-0 are 110 in the documented forms, the other values (which also copy the result
//into a register) are undocumented and treated as the documented form here
pub fn decode_index_cb(comptime base: h.IndexBase) OpcodeHandler {
    return struct {
        fn handler(state: *s.State) u8 {
            const d = fetchDisplacement(state);
            state.opcode = mem.read8(state, &state.pc);

            const operand = h.getRegister(.HL, state, base, d);
            const selector: u3 = @intCast((state.opcode >> 3) & 0b111);

            switch(state.opcode >> 6){
                0 => {
                    indexRotateShift(state, operand, selector);
                    return 23;
                },
                1 => {
                    cb.op_bit(state, operand, selector);
                    return 20;
                },
                2 => {
                    cb.op_res(operand, selector);
                    return 23;
                },
                3 => {
                    cb.op_set(operand, selector);
                    return 23;
                },
                else => unreachable,
            }
        }
    }.handler;
}

//the 8 rotates/shifts of the CB group, in opcode order (bits 5-3)
fn indexRotateShift(state: *s.State, operand: *u8, operation: u3) void {
    switch(operation){
        0 => h.op_rlc(state, operand),
        1 => h.op_rrc(state, operand),
        2 => h.op_rl(state, operand),
        3 => h.op_rr(state, operand),
        4 => cb.op_sla(state, operand),
        5 => cb.op_sra(state, operand),
        6 => cb.op_sll(state, operand),
        7 => cb.op_srl(state, operand),
    }

    //the operation helpers only set C, H and N: S, Z and P/V come from the result
    cb.setZSPFlag(state, operand.*);
}
