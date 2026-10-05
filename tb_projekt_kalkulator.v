`timescale 1ns / 1ps

module tb_projekt_kalkulator;

    // Testbench signals
    reg clk;
    reg rst;
    reg btn_enter_raw;
    reg btn_op_raw;
    reg [3:0] sw;
    wire [7:0] led;
    reg btn_frac_raw;
    reg btn_sign_mode_raw;

    // Test tracking
    integer pass_count;
    integer fail_count;
    integer test_num;

    // Instantiate DUT
    projekt_LD dut (
        .clk(clk),
        .rst(rst),
        .btn_enter_raw(btn_enter_raw),
        .sw(sw),
        .btn_op_raw(btn_op_raw),
        .led(led),
        .btn_frac_raw(btn_frac_raw),
        .btn_sign_mode_raw(btn_sign_mode_raw)
    );

    // Clock generation (10ns period = 100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Main test sequence
    initial begin
        $display("\n========================================");
        $display("=== Q8.8 Fixed-Point Calculator Test ===");
        $display("===    WITH DEBOUNCE INTEGRATION    ===");
        $display("========================================\n");

        // Initialize
        pass_count = 0;
        fail_count = 0;
        test_num = 0;
        rst = 1;
        btn_enter_raw = 0;
        btn_op_raw = 0;
        btn_frac_raw = 0;
        btn_sign_mode_raw = 0;
        sw = 4'b0000;
        #50;
        rst = 0;

        // Wait for debounce circuits to initialize (~10ms)
        $display("Initializing debounce circuits (10ms)...");
        #10_000_000;
        $display("Debounce initialization complete.\n");

        $display("=== UNSIGNED MODE TESTS ===\n");

        // ===== TEST 1: 3.25 + 1.5 = 4.75 =====
        $display("TEST 1: Addition (3.25 + 1.5)");
        $display("----------------------------------------");
        input_q8_8(16'h0340);  // A = 3.25
        input_q8_8(16'h0180);  // B = 1.5
        set_operation(2'b00);  // ADD
        #100;
        verify_result(16'h04C0, "3.25 + 1.5");  // Expected: 4.75
        test_led_display();

        // ===== TEST 2: 10.0 - 3.5 = 6.5 =====
        reset_calculator();
        $display("\nTEST 2: Subtraction (10.0 - 3.5)");
        $display("----------------------------------------");
        input_q8_8(16'h0A00);  // A = 10.0
        input_q8_8(16'h0380);  // B = 3.5
        set_operation(2'b01);  // SUB
        #100;
        verify_result(16'h0680, "10.0 - 3.5");  // Expected: 6.5
        test_led_display();

        // ===== TEST 3: 2.5 × 4.0 = 10.0 =====
        reset_calculator();
        $display("\nTEST 3: Multiplication (2.5 × 4.0)");
        $display("----------------------------------------");
        input_q8_8(16'h0280);  // A = 2.5
        input_q8_8(16'h0400);  // B = 4.0
        set_operation(2'b10);  // MUL
        #100;
        verify_result(16'h0A00, "2.5 × 4.0");  // Expected: 10.0
        test_led_display();

        // ===== TEST 4: 0.25 + 0.75 = 1.0 =====
        reset_calculator();
        $display("\nTEST 4: Fractional Addition (0.25 + 0.75)");
        $display("----------------------------------------");
        input_q8_8(16'h0040);  // A = 0.25
        input_q8_8(16'h00C0);  // B = 0.75
        set_operation(2'b00);  // ADD
        #100;
        verify_result(16'h0100, "0.25 + 0.75");  // Expected: 1.0
        test_led_display();

        // ===== TEST 5: Unsigned Overflow (200.5 + 100.5 = 255.996 saturated) =====
        reset_calculator();
        $display("\nTEST 5: Unsigned Addition Overflow (200.5 + 100.5)");
        $display("----------------------------------------");
        input_q8_8(16'hC880);  // A = 200.5
        input_q8_8(16'h6480);  // B = 100.5
        set_operation(2'b00);  // ADD
        #100;
        verify_result(16'hFFFF, "200.5 + 100.5 [saturated]");  // Expected: 255.996
        test_led_display();

        // ===== TEST 6: Unsigned Underflow (10.0 - 20.0 = 0.0 saturated) =====
        reset_calculator();
        $display("\nTEST 6: Unsigned Subtraction Underflow (10.0 - 20.0)");
        $display("----------------------------------------");
        input_q8_8(16'h0A00);  // A = 10.0
        input_q8_8(16'h1400);  // B = 20.0
        set_operation(2'b01);  // SUB
        #100;
        verify_result(16'h0000, "10.0 - 20.0 [saturated]");  // Expected: 0.0
        test_led_display();

        // ===== TEST 7: Unsigned Multiplication Overflow (50.0 × 10.0 = 255.996 saturated) =====
        reset_calculator();
        $display("\nTEST 7: Unsigned Multiplication Overflow (50.0 × 10.0)");
        $display("----------------------------------------");
        input_q8_8(16'h3200);  // A = 50.0
        input_q8_8(16'h0A00);  // B = 10.0
        set_operation(2'b10);  // MUL
        #100;
        verify_result(16'hFFFF, "50.0 × 10.0 [saturated]");  // Expected: 255.996
        test_led_display();

        // ===== SWITCH TO SIGNED MODE =====
        $display("\n=== SIGNED MODE TESTS ===\n");
        set_sign_mode(1);  // Enable signed mode

        // ===== TEST 8: Signed Addition (-50.5 + 30.25 = -20.25) =====
        reset_calculator();
        set_sign_mode(1);
        $display("\nTEST 8: Signed Addition (-50.5 + 30.25)");
        $display("----------------------------------------");
        input_q8_8(16'hCD80);  // A = -50.5 (two's complement)
        input_q8_8(16'h1E40);  // B = 30.25
        set_operation(2'b00);  // ADD
        #100;
        verify_result(16'hEBC0, "-50.5 + 30.25");  // Expected: -20.25
        test_led_display();

        // ===== TEST 9: Signed Overflow (100.5 + 50.5 = 127.996 saturated) =====
        reset_calculator();
        set_sign_mode(1);
        $display("\nTEST 9: Signed Addition Overflow (100.5 + 50.5)");
        $display("----------------------------------------");
        input_q8_8(16'h6480);  // A = 100.5
        input_q8_8(16'h3280);  // B = 50.5
        set_operation(2'b00);  // ADD
        #100;
        verify_result(16'h7FFF, "100.5 + 50.5 [saturated]");  // Expected: 127.996
        test_led_display();

        // ===== TEST 10: Signed Underflow (-100.5 - 50.5 = -128.0 saturated) =====
        reset_calculator();
        set_sign_mode(1);
        $display("\nTEST 10: Signed Subtraction Underflow (-100.5 - 50.5)");
        $display("----------------------------------------");
        input_q8_8(16'h9B80);  // A = -100.5 (two's complement)
        input_q8_8(16'h3280);  // B = 50.5
        set_operation(2'b01);  // SUB
        #100;
        verify_result(16'h8000, "-100.5 - 50.5 [saturated]");  // Expected: -128.0
        test_led_display();

        // ===== TEST 11: Signed Multiplication (-5.0 × 10.0 = -50.0) =====
        reset_calculator();
        set_sign_mode(1);
        $display("\nTEST 11: Signed Multiplication (-5.0 × 10.0)");
        $display("----------------------------------------");
        input_q8_8(16'hFB00);  // A = -5.0 (two's complement)
        input_q8_8(16'h0A00);  // B = 10.0
        set_operation(2'b10);  // MUL
        #100;
        verify_result(16'hCE00, "-5.0 × 10.0");  // Expected: -50.0
        test_led_display();

        // ===== TEST 12: Signed Multiplication Overflow (20.0 × 10.0 = 127.996 saturated) =====
        reset_calculator();
        set_sign_mode(1);
        $display("\nTEST 12: Signed Multiplication Overflow (20.0 × 10.0)");
        $display("----------------------------------------");
        input_q8_8(16'h1400);  // A = 20.0
        input_q8_8(16'h0A00);  // B = 10.0
        set_operation(2'b10);  // MUL
        #100;
        verify_result(16'h7FFF, "20.0 × 10.0 [saturated]");  // Expected: 127.996
        test_led_display();

        // ===== TEST SUMMARY =====
        $display("\n========================================");
        $display("=== TEST SUMMARY ===");
        $display("========================================");
        $display("Total Tests: %0d", pass_count + fail_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        if (fail_count == 0)
            $display("\n*** ALL TESTS PASSED ***\n");
        else
            $display("\n*** SOME TESTS FAILED ***\n");

        $stop;
    end

    // ===== TASKS =====

    // Press enter button with realistic bounce
    task press_enter;
        integer i;
        begin
            // Press with bouncing (6 bounces over 3ms)
            for (i = 0; i < 6; i = i + 1) begin
                btn_enter_raw = 1;
                #250_000;  // 0.25ms
                btn_enter_raw = 0;
                #250_000;  // 0.25ms
            end

            // Stable pressed state
            btn_enter_raw = 1;
            #5_000_000;  // Hold for 5ms

            // Release with bouncing (4 bounces over 2ms)
            for (i = 0; i < 4; i = i + 1) begin
                btn_enter_raw = 0;
                #250_000;
                btn_enter_raw = 1;
                #250_000;
            end

            // Final release
            btn_enter_raw = 0;

            // Wait for debounce to complete (~10ms)
            #10_000_000;
        end
    endtask

    // Press operation button with realistic bounce
    task press_op;
        integer i;
        begin
            // Press with bouncing
            for (i = 0; i < 6; i = i + 1) begin
                btn_op_raw = 1;
                #250_000;
                btn_op_raw = 0;
                #250_000;
            end

            // Stable pressed
            btn_op_raw = 1;
            #5_000_000;

            // Release with bouncing
            for (i = 0; i < 4; i = i + 1) begin
                btn_op_raw = 0;
                #250_000;
                btn_op_raw = 1;
                #250_000;
            end

            // Final release
            btn_op_raw = 0;

            // Wait for debounce
            #10_000_000;
        end
    endtask

    // Toggle fractional display button with realistic bounce
    task press_frac;
        integer i;
        begin
            // Press with bouncing
            for (i = 0; i < 6; i = i + 1) begin
                btn_frac_raw = 1;
                #250_000;
                btn_frac_raw = 0;
                #250_000;
            end

            // Stable pressed
            btn_frac_raw = 1;
            #5_000_000;

            // Release with bouncing
            for (i = 0; i < 4; i = i + 1) begin
                btn_frac_raw = 0;
                #250_000;
                btn_frac_raw = 1;
                #250_000;
            end

            // Final release
            btn_frac_raw = 0;

            // Wait for debounce
            #10_000_000;
        end
    endtask

    // Toggle sign mode button with realistic bounce
    task press_sign_mode;
        integer i;
        begin
            // Press with bouncing
            for (i = 0; i < 6; i = i + 1) begin
                btn_sign_mode_raw = 1;
                #250_000;
                btn_sign_mode_raw = 0;
                #250_000;
            end

            // Stable pressed
            btn_sign_mode_raw = 1;
            #5_000_000;

            // Release with bouncing
            for (i = 0; i < 4; i = i + 1) begin
                btn_sign_mode_raw = 0;
                #250_000;
                btn_sign_mode_raw = 1;
                #250_000;
            end

            // Final release
            btn_sign_mode_raw = 0;

            // Wait for debounce
            #10_000_000;
        end
    endtask

    // Set sign mode (0=unsigned, 1=signed)
    task set_sign_mode;
        input mode;
        begin
            // Toggle if current mode doesn't match desired mode
            if (dut.signed_mode != mode) begin
                press_sign_mode();
            end
        end
    endtask

    // Input a Q8.8 number (16-bit value)
    task input_q8_8;
        input [15:0] value;
        begin
            // Integer part - high nibble [15:12]
            sw = value[15:12];
            press_enter();

            // Integer part - low nibble [11:8]
            sw = value[11:8];
            press_enter();

            // Fractional part - high nibble [7:4]
            sw = value[7:4];
            press_enter();

            // Fractional part - low nibble [3:0]
            sw = value[3:0];
            press_enter();
        end
    endtask

    // Set operation mode
    task set_operation;
        input [1:0] op_code;
        integer i;
        begin
            // Press op button until we reach desired operation
            for (i = 0; i < op_code; i = i + 1) begin
                press_op();
            end
        end
    endtask

    // Reset calculator to initial state
    task reset_calculator;
    begin
        rst = 1;
        #50;
        rst = 0;
        #20;
    end
    endtask

    // Verify result and display pass/fail
    task verify_result;
        input [15:0] expected;
        input [127*8:1] test_name;
        real a_real, b_real, expected_real, actual_real;
        begin
            test_num = test_num + 1;

            // Convert to real numbers based on signed_mode
            if (dut.signed_mode) begin
                // Signed interpretation
                a_real = $itor($signed(dut.a)) / 256.0;
                b_real = $itor($signed(dut.b)) / 256.0;
                expected_real = $itor($signed(expected)) / 256.0;
                actual_real = $itor($signed(dut.result)) / 256.0;
            end else begin
                // Unsigned interpretation
                a_real = $itor(dut.a) / 256.0;
                b_real = $itor(dut.b) / 256.0;
                expected_real = $itor(expected) / 256.0;
                actual_real = $itor(dut.result) / 256.0;
            end

            // Display values
            $display("  A        = %f (0x%04h)", a_real, dut.a);
            $display("  B        = %f (0x%04h)", b_real, dut.b);
            $display("  Expected = %f (0x%04h)", expected_real, expected);
            $display("  Actual   = %f (0x%04h)", actual_real, dut.result);

            // Check result (silent)
            if (dut.result == expected) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Test LED display for both integer and fractional parts
    task test_led_display;
        begin
            // Check integer display (default)
            // Level debouncer takes ~7.5ms (3 slow_clk cycles) to propagate
            btn_frac_raw = 0;
            #8_000_000;  // Wait 8ms for level to stabilize
            $display("  LED Integer Display: 0x%02h", led);

            // Check fractional display - hold button high
            btn_frac_raw = 1;
            #8_000_000;  // Wait 8ms for level to propagate through debouncer
            $display("  LED Frac Display: 0x%02h\n", led);

            // Return to integer display
            btn_frac_raw = 0;
            #8_000_000;  // Wait 8ms for level to return
        end
    endtask

endmodule
