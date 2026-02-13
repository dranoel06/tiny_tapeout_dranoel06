# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# Instruction Opcodes (aus deinem Verilog Code)
# Format: [Opcode 4-bit] [Operand/Address 4-bit]
LDA = 0x10  # Load A
ADD = 0x20  # Add to A
OUT = 0x30  # Output A
JMP = 0x40  # Jump
STA = 0x50  # Store A
LDI = 0x60  # Load Immediate into A
SUB = 0x70  # Subtract from A
BEQ = 0x80  # Branch if Equal
CMP = 0x90  # Compare

async def program_ram(dut, address, data):
    """Hilfsfunktion: Schreibt ein Byte in das RAM der CPU"""
    # prog-Bit (uio_in[7]) auf 1 setzen, Adresse auf uio_in[3:0]
    dut.uio_in.value = (1 << 7) | (address & 0x0F) 
    # Daten anlegen
    dut.ui_in.value = data
    # Einen Takt warten, damit das RAM es übernimmt
    await ClockCycles(dut.clk, 1)

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start CPU Test")

    # Takt starten (z.B. 100 kHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # 1. Reset und Initialisierung
    dut._log.info("Resetting CPU")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0 # Active Low Reset
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1 # CPU ist jetzt einsatzbereit

    # 2. Programm in das RAM schreiben
    dut._log.info("Programming RAM")
    
    # Unser kleines Testprogramm:
    # Berechne: 20 + 30 = 50
    # Wir laden 20 direkt, speichern es, addieren 30 und geben es aus.
    
    # Adresse 0: LDI 20 (Lade den Wert 20 in Reg A) -> Hier Achtung: LDI lädt nur 4 Bit laut deinem Code!
    # Deinem Code nach macht LDI: a_reg <= {4'b0, bus[3:0]}.
    # Lass uns lieber LDA und RAM Werte nutzen, das ist sicherer für 8-Bit Werte.
    
    # Programm-Code (in die unteren Adressen)
    await program_ram(dut, 0, LDA | 0x0A) # Lade Wert von Adresse 10 in A
    await program_ram(dut, 1, ADD | 0x0B) # Addiere Wert von Adresse 11 zu A
    await program_ram(dut, 2, OUT | 0x00) # Gib A auf uo_out aus
    await program_ram(dut, 3, JMP | 0x03) # Endlosschleife hier auf Adresse 3
    
    # Daten (in die oberen Adressen)
    await program_ram(dut, 10, 20)        # Wert 1: 20
    await program_ram(dut, 11, 30)        # Wert 2: 30

    # 3. Programm-Modus beenden, CPU laufen lassen
    dut._log.info("Running Program")
    dut.uio_in.value = 0 # prog-Bit (Bit 7) wieder auf 0
    dut.ui_in.value = 0

    # 4. Warten, bis das Programm abgearbeitet ist
    # Jeder Befehl braucht 6 Taktzyklen. Wir haben 3 Befehle bis zum OUT.
    # 3 * 6 = 18 Zyklen. Wir warten großzügig 30 Zyklen.
    await ClockCycles(dut.clk, 30)

    # 5. Ergebnis überprüfen
    dut._log.info(f"Checking Output, expecting 50. Got: {int(dut.uo_out.value)}")
    assert dut.uo_out.value == 50

    dut._log.info("Test passed successfully!")
