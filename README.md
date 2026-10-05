# Q8.8 Kalkulator s Fiksnom Točkom za FPGA

Hardverska implementacija kalkulatora s Q8.8 fixed-point aritmetikom (signed/unsigned), saturacijom i debounce funkcijom za Xilinx Spartan-3E FPGA.

## Značajke

- **Q8.8 fixed-point aritmetika** - 8 bitova cijeli broj, 8 bitova razlomak (rezolucija 1/256)
- **Signed i unsigned modovi** - Preklapanje između dva načina rada
- **Saturacija** - Sprječava overflow/underflow automatskim ograničenjem
- **Hardverski debounce** - Filtrira mehaničko odbijanje tipki (5ms debounce)
- **Tri operacije** - Zbrajanje, oduzimanje, množenje
- **LED prikaz** - Prikazuje cijeli ili razlomljeni dio na 8 LED-ica

## Specifikacije

| Značajka | Vrijednost |
|----------|------------|
| **Format brojeva** | Q8.8 (16 bitova) |
| **Unsigned raspon** | 0 do 255.996094 |
| **Signed raspon** | -128.0 do 127.996094 |
| **Rezolucija** | 1/256 = 0.00390625 |
| **Takt** | 100 MHz |
| **Debounce vrijeme** | ~5ms (pulse), ~7.5ms (level) |
| **Operacije** | ADD, SUB, MUL sa saturacijom |
| **FPGA** | Xilinx Spartan-3E |

---

## Kreiranje Novog ISE Projekta

Ako počinjete s novim projektom, slijedite ove korake:

1. **Pokrenite ISE Project Navigator:**
   - Start → All Programs → Xilinx ISE 10.1 → Project Navigator

2. **Kreirajte novi projekt:**
   - File → New Project
   - Project Name: `projekt_kalkulator`
   - Top-Level Source Type: HDL
   - Device Properties:
     - Family: Spartan3
     - Device: XC3S200
     - Package: FT256
     - Speed: -4
     - Synthesis Tool: XST (VHDL/Verilog)
     - Simulator: ISE Simulator (VHDL/Verilog)
     - Preferred Language: Verilog

3. **Dodajte postojeće datoteke:**
   - Project → Add Source
   - Odaberite: `top.v`, `debounce.v`
   - Za simulaciju: dodajte `tb_projekt_kalkulator.v`, `tb_debounce.v`

4. **Dodajte UCF datoteku:**
   - Project → Add Source
   - Odaberite `projekt_kalkulator.ucf`

---

## Brzi Početak - Simulacija

### Preduvjeti
- Xilinx ISE 10.1
- Spartan-3E FPGA Starter Kit 

### Pokretanje Simulacije

1. **Otvaranje ISE Project Navigator:**
   ```
   Start → All Programs → Xilinx ISE 10.1 → Project Navigator
   ```

2. **Otvaranje projekta:**
   - File → Open Project
   - Odaberite `projekt_kalkulator.ise` datoteku iz projekta

3. **Pokretanje simulacije kalkulatora:**
   - U Sources panelu, odaberite "Behavioral Simulation" iz padajućeg izbornika
   - Odaberite testbench datoteku `tb_projekt_kalkulator`
   - U Processes panelu, proširite "Xilinx ISE Simulator"
   - Dvostruki klik na "Simulate Behavioral Model"
   - Trajanje: ~3-4 sekunde

3. **Očekivani izlaz:**
   ```
   TEST 1: Addition (3.25 + 1.5)
   ----------------------------------------
     A        = 3.250000 (0x0340)
     B        = 1.500000 (0x0180)
     Expected = 4.750000 (0x04c0)
     Actual   = 4.750000 (0x04c0)
     LED Integer Display: 0x04
     LED Frac Display: 0xc0

   === TEST SUMMARY ===
   Total Tests: 12
   Passed:      12
   Failed:      0
   *** ALL TESTS PASSED ***
   ```

4. **Debounce unit testovi:**
   - U Sources panelu, odaberite "Behavioral Simulation"
   - Odaberite testbench `tb_debounce`
   - Dvostruki klik na "Simulate Behavioral Model" u Processes panelu
   - Očekivano: 7/7 testova prolazi

---

## Q8.8 Format - Osnove

Q8.8 format koristi 16 bitova za prikaz brojeva s razlomcima:

```
┌─────────────────┬─────────────────┐
│  Cijeli (8b)    │  Razlomak (8b)  │
│   [15:8]        │     [7:0]       │
└─────────────────┴─────────────────┘
```

**Primjeri:**
- `3.25  = 0x0340`
- `-5.5  = 0xFA80` (two's complement)
- `0.5   = 0x0080`

**Konverzija:**
- **U Q8.8:** `q8_8 = vrijednost × 256`
- **Iz Q8.8:** `vrijednost = q8_8 / 256.0`

**Rasponi:**
- **Unsigned:** 0 do 255.996094
- **Signed:** -128.0 do 127.996094

---

## Postavljanje Hardvera (Spartan-3E)

### Dodjela Pinova

| Signal | Spartan-3E Pin | IOSTANDARD | Opis |
|--------|----------------|------------|------|
| **Ulazi** | | | |
| `clk` | C9 | LVCMOS33 | 100MHz takt |
| `rst` | K17 (BTN_SOUTH) | LVTTL+PULLDOWN | Reset tipka |
| `btn_enter_raw` | V4 (BTN_NORTH) | LVTTL+PULLDOWN | Potvrdi unos |
| `btn_op_raw` | H13 (BTN_EAST) | LVTTL+PULLDOWN | Promijeni operaciju |
| `btn_sign_mode_raw` | D18 (BTN_WEST) | LVTTL+PULLDOWN | Signed/Unsigned |
| `btn_frac_raw` | V16 (ROT_CENTER) | LVTTL+PULLDOWN | Prikaži razlomak |
| `sw[0]` | L13 | LVTTL+PULLUP | Prekidač 0 (LSB) |
| `sw[1]` | L14 | LVTTL+PULLUP | Prekidač 1 |
| `sw[2]` | H18 | LVTTL+PULLUP | Prekidač 2 |
| `sw[3]` | N17 | LVTTL+PULLUP | Prekidač 3 (MSB) |
| **Izlazi** | | | |
| `led[0]` | F12 | LVTTL | LED 0 (LSB) |
| `led[1]` | E12 | LVTTL | LED 1 |
| `led[2]` | E11 | LVTTL | LED 2 |
| `led[3]` | F11 | LVTTL | LED 3 |
| `led[4]` | C11 | LVTTL | LED 4 |
| `led[5]` | D11 | LVTTL | LED 5 |
| `led[6]` | E9 | LVTTL | LED 6 |
| `led[7]` | F9 | LVTTL | LED 7 (MSB) |

### UCF Datoteka Ograničenja

Kreirajte datoteku `spartan3e_constraints.ucf`:

```tcl
# ============================================================================
# Spartan-3E Starter Kit - User Constraints File (UCF)
# Q8.8 Fixed-Point Calculator
# ============================================================================

# ============ TAKT ============
NET "clk" LOC = "C9" | IOSTANDARD = LVCMOS33;

# ============ TIPKE ============
NET "rst" LOC = "K17" | IOSTANDARD = LVTTL | PULLDOWN;                  # BTN_SOUTH
NET "btn_enter_raw" LOC = "V4" | IOSTANDARD = LVTTL | PULLDOWN;         # BTN_NORTH
NET "btn_op_raw" LOC = "H13" | IOSTANDARD = LVTTL | PULLDOWN;           # BTN_EAST
NET "btn_sign_mode_raw" LOC = "D18" | IOSTANDARD = LVTTL | PULLDOWN;    # BTN_WEST
NET "btn_frac_raw" LOC = "V16" | IOSTANDARD = LVTTL | PULLDOWN;         # ROT_CENTER

# ============ PREKIDAČI (SW0 - SW3) ============
NET "sw<0>" LOC = "L13" | IOSTANDARD = LVTTL | PULLUP;
NET "sw<1>" LOC = "L14" | IOSTANDARD = LVTTL | PULLUP;
NET "sw<2>" LOC = "H18" | IOSTANDARD = LVTTL | PULLUP;
NET "sw<3>" LOC = "N17" | IOSTANDARD = LVTTL | PULLUP;

# ============ LED-ICE (LD0 - LD7) ============
NET "led<0>" LOC = "F12" | IOSTANDARD = LVTTL;
NET "led<1>" LOC = "E12" | IOSTANDARD = LVTTL;
NET "led<2>" LOC = "E11" | IOSTANDARD = LVTTL;
NET "led<3>" LOC = "F11" | IOSTANDARD = LVTTL;
NET "led<4>" LOC = "C11" | IOSTANDARD = LVTTL;
NET "led<5>" LOC = "D11" | IOSTANDARD = LVTTL;
NET "led<6>" LOC = "E9" | IOSTANDARD = LVTTL;
NET "led<7>" LOC = "F9" | IOSTANDARD = LVTTL;
```

### Programiranje FPGA-a

1. **Generiranje Bitstream Datoteke:**
   - U ISE Project Navigator, odaberite "Implementation" pogled
   - Odaberite top-level modul (`projekt_kalkulator`)
   - U Processes panelu, proširite "Generate Programming File"
   - Dvostruki klik na "Generate Programming File"
   - Čekajte završetak (~5-10 minuta)
   - Bitstream datoteka: `projekt_kalkulator.bit`

2. **Programiranje Uređaja pomoću iMPACT:**
   - Povežite Spartan-3E ploču USB JTAG kabelom
   - Uključite napajanje ploče (5V DC adapter)
   - U Processes panelu, dvostruki klik na "Configure Target Device"
   - iMPACT alat će se otvoriti

   **iMPACT Konfiguracija:**
   - Odaberite "Configure devices using Boundary-Scan (JTAG)"
   - Označite "Automatically connect to a cable and identify Boundary-Scan chain"
   - Kliknite "Finish"
   - Kada se pojavi upit za konfiguracijsku datoteku, odaberite `projekt_kalkulator.bit`
   - Kliknite "Bypass" za ostale uređaje u lancu
   - Desni klik na xc3s200 uređaj → "Program..."
   - Kliknite "OK" za pokretanje programiranja

3. **Provjera:**
   - Kada se pojavi "Program Succeeded", programiranje je uspješno
   - LED-ice 0-3 će pokazivati trenutnu vrijednost brojača
   - Pritisnite BTN_SOUTH (rst) za reset kalkulatora

---

## Upute za Korištenje

### Tijek Rada

```
1. Reset kalkulatora       → Pritisnite BTN_SOUTH
2. Postavite signed mod    → Pritisnite BTN_WEST (LED[7]=1 tijekom unosa)
3. Unesite prvi broj A     → 4 pritiska tipke 
4. Unesite drugi broj B    → 4 pritiska tipke
5. Odaberite operaciju     → Pritisnite BTN_EAST (ADD→SUB→MUL)
6. Prikaz rezultata        → LED-ice prikazuju cijeli dio
7. Prikaz razlomka         → Držite ROT_CENTER
```

### Kontrole

| Tipka | Funkcija | Ponašanje |
|-------|----------|-----------|
| **BTN_NORTH** | Enter/Potvrda | Unosi trenutnu vrijednost prekidača |
| **BTN_EAST** | Operacija | Kruži: ADD → SUB → MUL → ADD... |
| **BTN_WEST** | Sign Mod | Prebacuje: UNSIGNED ⇄ SIGNED |
| **BTN_SOUTH** | Reset | Resetira kalkulator na početak |
| **ROT_CENTER** | Razlomak | Držite za prikaz razlomljenog dijela |

### Primjer 1: Zbrajanje (3.25 + 1.5)

**Postavke:**
- Mod: Unsigned (ne pritišćite BTN_WEST)
- Operacija: ADD (zadano)

**Korak po korak:**

1. **Reset:** Pritisnite BTN_SOUTH

2. **Unos A = 3.25 (0x0340):**
   - Postavite SW[3:0] = `0000` (0x0), pritisnite BTN_NORTH
   - Postavite SW[3:0] = `0011` (0x3), pritisnite BTN_NORTH
   - Postavite SW[3:0] = `0100` (0x4), pritisnite BTN_NORTH
   - Postavite SW[3:0] = `0000` (0x0), pritisnite BTN_NORTH

3. **Unos B = 1.5 (0x0180):**
   - Postavite SW[3:0] = `0000` (0x0), pritisnite BTN_NORTH
   - Postavite SW[3:0] = `0001` (0x1), pritisnite BTN_NORTH
   - Postavite SW[3:0] = `1000` (0x8), pritisnite BTN_NORTH
   - Postavite SW[3:0] = `0000` (0x0), pritisnite BTN_NORTH

4. **Rezultat:**
   - LED-ice: `00000100` (0x04) = cijeli dio = 4
   - Držite ROT_CENTER: `11000000` (0xC0) = razlomak = 0.75
   - **Rezultat: 4.75** 

### Primjer 2: Signed Zbrajanje (-50.5 + 30.25)

**Postavke:**
- Mod: Signed
- Operacija: ADD

**Korak po korak:**

1. **Reset:** Pritisnite BTN_SOUTH

2. **Omogući signed mod:** Pritisnite BTN_WEST
   - LED[7] će biti upaljeno tijekom unosa (indikator signed moda)

3. **Unos A = -50.5 (0xCD80):**
   - Za negativne brojeve koristite two's complement
   - Izračun: 50.5 → 0x3280 → invertiraj → 0xCD7F → +1 → 0xCD80
   - Postavite SW[3:0] = `1100` (0xC), pritisnite BTN_NORTH
   - Postavite SW[3:0] = `1101` (0xD), pritisnite BTN_NORTH
   - Postavite SW[3:0] = `1000` (0x8), pritisnite BTN_NORTH
   - Postavite SW[3:0] = `0000` (0x0), pritisnite BTN_NORTH

4. **Unos B = 30.25 (0x1E40):**
   - Postavite SW[3:0] = `0001` (0x1), pritisnite BTN_NORTH
   - Postavite SW[3:0] = `1110` (0xE), pritisnite BTN_NORTH
   - Postavite SW[3:0] = `0100` (0x4), pritisnite BTN_NORTH
   - Postavite SW[3:0] = `0000` (0x0), pritisnite BTN_NORTH

5. **Rezultat:**
   - LED-ice: `11101011` (0xEB) = -21 (two's complement)
   - Držite ROT_CENTER: `11000000` (0xC0) = razlomak
   - **Rezultat: -20.25** 

### Primjer 3: Saturacija (Overflow)

**Unos:** 200.5 + 100.5 (unsigned mod)

**Očekivano:** 301.0 → **Saturira na 255.996** (0xFFFF)

**Rezultat:**
- LED-ice: `11111111` (0xFF) = 255 (saturirano)
- Razlomak: `11111111` (0xFF) = 0.996
- **Rezultat: 255.996** (maksimalna unsigned vrijednost) 

---

## Struktura Projekta

```
fix_point_calc/
├── README.md                          # Ova datoteka
├── projekt_kalkulator.ise             # ISE projekt datoteka
├── projekt_kalkulator.ucf             # UCF constraints
├── top.v                              # Glavni kalkulator modul (projekt_LD)
├── debounce.v                         # Debounce moduli
├── tb_projekt_kalkulator.v            # Kalkulator testbench
├── tb_debounce.v                      # Debounce testbench
├── _ngo/                              # NGO datoteke (generirano)
├── _xmsgs/                            # Poruke (generirano)
├── iseconfig/                         # ISE konfiguracija
└── projekt_kalkulator.bit             # Bitstream datoteka (nakon implementacije)
```

### Opisi Modula

**top.v - projekt_kalkulator**
- Glavni modul kalkulatora s Q8.8 aritmetikom i saturacijom

**debounce.v - debounce**
- Pulse-based debouncer za tipke događaja (enter, op, sign_mode)

**debounce.v - debounce_level**
- Level-based debouncer za prikaz kontrolu (btn_frac)

**debounce.v - clock_div**
- Dijeli 100MHz na 400Hz za debounce

**debounce.v - my_dff**
- D flip-flop za pipeline stupnjeve

**tb_projekt_kalkulator.v**
- Testbench za kalkulator (12 testova)

**tb_debounce.v**
- Testbench za debounce (7 testova)

---

## Q8.8 Referentna Tablica

| Decimalno | Hex | Binarno |
|-----------|-----|---------|
| 0.0 | 0x0000 | 0000_0000.0000_0000 |
| 0.25 | 0x0040 | 0000_0000.0100_0000 |
| 0.5 | 0x0080 | 0000_0000.1000_0000 |
| 1.0 | 0x0100 | 0000_0001.0000_0000 |
| 3.25 | 0x0340 | 0000_0011.0100_0000 |
| 10.0 | 0x0A00 | 0000_1010.0000_0000 |
| 100.0 | 0x6400 | 0110_0100.0000_0000 |
| 127.996 | 0x7FFF | 0111_1111.1111_1111 |
| 255.996 | 0xFFFF | 1111_1111.1111_1111 |
| -1.0 | 0xFF00 | 1111_1111.0000_0000 |
| -50.5 | 0xCD80 | 1100_1101.1000_0000 |
| -128.0 | 0x8000 | 1000_0000.0000_0000 |

---

Autor: Lana Pelaić


