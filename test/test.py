# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

async def program_ram(dut, address, data):
    """Hilfsfunktion: Schreibt ein Byte in das RAM der CPU"""
    # prog-Bit (uio_in[7]) = 1, Adresse = uio_in[3:0]
    dut.uio_in.value = (1 << 7) | (address & 0x0F)
    dut.ui_in.value = data
    await ClockCycles(dut.clk, 1)

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start CPU Test")

    # 1. Takt starten (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # 2. Reset AKTIVIEREN (CPU einfrieren)
    dut._log.info("Reset aktiv. CPU angehalten.")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0 # Active Low Reset
    
    # Ein paar Takte warten, damit der Reset im gesamten Chip ankommt
    await ClockCycles(dut.clk, 5)

    # 3. RAM programmieren WÄHREND die CPU im Reset ist
    dut._log.info("Initialisiere gesamtes RAM mit 0 (gegen X-Zustände)...")
    for i in range(16):
        await program_ram(dut, i, 0x00)
        
    dut._log.info("Programmiere Test-Programm...")
    # Opcodes laut deinem Verilog: LDI = 6, OUT = 3, JMP = 4
    # Format: [Opcode 4-bit][Operand 4-bit]
    
    # Adresse 0: LDI 5  (Opcode 6, Wert 5 -> Hex: 0x65)
    await program_ram(dut, 0, 0x65) 
    
    # Adresse 1: OUT    (Opcode 3, Operand egal -> Hex: 0x30)
    await program_ram(dut, 1, 0x30) 
    
    # Adresse 2: JMP 2  (Opcode 4, Ziel Adr 2 -> Hex: 0x42)
    await program_ram(dut, 2, 0x42) 

    # Programm-Modus beenden (prog Bit auf 0)
    dut.uio_in.value = 0
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 2)

    # 4. Reset AUFHEBEN -> CPU startet bei Programm Counter = 0
    dut._log.info("Reset aufgehoben. CPU startet Ausführung!")
    dut.rst_n.value = 1

    # 5. Ausführung abwarten
    # Dein Design nutzt einen festen 6-Schritte-Zyklus pro Befehl.
    # LDI (6 Takte) + OUT (6 Takte) = 12 Takte. 
    # Wir warten zur Sicherheit 20 Takte.
    await ClockCycles(dut.clk, 20)

    # 6. Ergebnis auswerten und sicher abfangen
    output_signal = dut.uo_out.value
    
    if output_signal.is_resolvable:
        ergebnis = int(output_signal)
        dut._log.info(f"Ergebnis an uo_out ist: {ergebnis}")
        assert ergebnis == 5, f"Erwartet: 5, Bekommen: {ergebnis}"
    else:
        # Falls in der Gate-Level Sim doch noch was schiefgeht, sehen wir HIER warum!
        dut._log.error(f"X/Z Zustand erkannt! Die Hardware liefert: {output_signal.binstr}")
        assert False, "Ausgangssignal ist undefiniert (X)."
        
    dut._log.info("Test erfolgreich bestanden!")
