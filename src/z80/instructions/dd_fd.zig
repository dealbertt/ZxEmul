const h = @import("helpers.zig");
fn indexedPair(r: h.Reg16Bit, base: h.IndexBase) h.Reg16Bit {
    //the way the decoding works, IX and IY are not identified, so they would all register as HL, thats why if r != from HL, its not one of those 3
    if(r !=  .HL) return r;
    return switch (base) {
        .HL => .HL,
        .IX => .IX,
        .IY => .IY,
    };
}

