//yeah sure, this will handle the timing of the z80 cpu
//
//i believe the z80 has a base freq of 3,5 mhz -> 3.500.000 cycles per second
//and the original zxspectrum screen runs at 50hz, which could mean
//70.000 cycles per screen refresh
//
//
//
//but each instruction has a number of different cycles that it takes to execute
//
//
//the most basic implementation of timing would be, assign to each instruction (maybe on the table?), the number of cycles per instruction, and the just
const std = @import("std");
const rl = @import("raylib");

const SPECTRUM_FRAME_TIME: f32 = 1.0 / 50.0; //0.02 
                                            
pub var frame_accumulator: f32 = 0.0;

const CYCLES_PER_FRAME: f32 = 3500000 / 50.0;
