`timescale 1ns / 1ps

module tb_debounce;

    // Testbench signals
    reg pb_1;
    reg clk;
    wire pb_out;

    // Test tracking
    integer pass_count;
    integer fail_count;
    integer pulse_count;
    integer slow_clk_period;
    real measured_freq;

    // Time measurements
    time last_slow_clk_edge;
    time pulse_start_time;
    time pulse_end_time;

    // Instantiate DUT
    debounce dut (
        .pb_1(pb_1),
        .clk(clk),
        .pb_out(pb_out)
    );

    // Clock generation (100MHz = 10ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // Pulse counter - count pb_out pulses
    always @(posedge pb_out) begin
        pulse_count = pulse_count + 1;
        $display("  [%0t] Pulse detected! (count = %0d)", $time, pulse_count);
    end

    // Main test sequence
    initial begin
        $display("\n========================================");
        $display("=== Debounce Module Unit Test ===");
        $display("========================================\n");

        // Initialize
        pass_count = 0;
        fail_count = 0;
        pulse_count = 0;
        pb_1 = 0;
        slow_clk_period = 0;
        last_slow_clk_edge = 0;

        // Wait for circuit initialization and stabilization
        // Need at least 3 slow_clk cycles (~7.5ms) for flip-flops to settle
        $display("Waiting for circuit initialization (10ms)...\n");
        #10_000_000;  // 10ms

        // ===== TEST 1: Clean Button Press =====
        $display("TEST 1: Clean Button Press (No Bounce)");
        $display("----------------------------------------");
        pulse_count = 0;
        simulate_clean_press(20_000_000);  // 20ms press
        #30_000_000;  // Wait 30ms
        verify_pulse_count(1, "Clean press should produce exactly 1 pulse");

        // ===== TEST 2: Realistic Bouncing Pattern =====
        $display("\nTEST 2: Realistic Bouncing Pattern");
        $display("----------------------------------------");
        pulse_count = 0;
        simulate_bouncy_press(8, 5_000_000);  // 8 bounces over 5ms
        #30_000_000;
        verify_pulse_count(1, "Bouncy press should still produce only 1 pulse");

        // ===== TEST 3: Severe Bouncing =====
        $display("\nTEST 3: Severe Bouncing Pattern");
        $display("----------------------------------------");
        pulse_count = 0;
        simulate_bouncy_press(20, 10_000_000);  // 20 bounces over 10ms
        #30_000_000;
        verify_pulse_count(1, "Severe bouncing should still produce only 1 pulse");

        // ===== TEST 4: Glitch Rejection =====
        $display("\nTEST 4: Glitch Rejection (Short Pulse)");
        $display("----------------------------------------");
        pulse_count = 0;
        simulate_glitch(500_000);  // 0.5ms glitch
        #20_000_000;
        verify_pulse_count(0, "Short glitch should be ignored (0 pulses)");

        // ===== TEST 5: Long Press and Hold =====
        $display("\nTEST 5: Long Press and Hold");
        $display("----------------------------------------");
        pulse_count = 0;
        pb_1 = 1;
        #50_000_000;  // Hold for 50ms
        pb_1 = 0;
        #10_000_000;
        verify_pulse_count(1, "Long press should produce only 1 pulse at start");

        // ===== TEST 6: Multiple Rapid Presses =====
        $display("\nTEST 6: Multiple Rapid Presses");
        $display("----------------------------------------");
        pulse_count = 0;
        simulate_clean_press(10_000_000);  // First press
        #15_000_000;  // Wait 15ms
        simulate_clean_press(10_000_000);  // Second press
        #15_000_000;
        simulate_clean_press(10_000_000);  // Third press
        #20_000_000;
        verify_pulse_count(3, "Three separate presses should produce 3 pulses");

        // ===== TEST 7: Clock Frequency Verification =====
        $display("\nTEST 7: Slow Clock Frequency Verification");
        $display("----------------------------------------");
        measure_slow_clock();
        verify_clock_frequency();

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

    // ===== HELPER TASKS =====

    // Simulate clean button press (no bouncing)
    task simulate_clean_press;
        input integer duration_ns;
        begin
            $display("  Simulating clean press for %0d ms", duration_ns / 1_000_000);
            pb_1 = 1;
            #duration_ns;
            pb_1 = 0;
        end
    endtask

    // Simulate bouncy button press with realistic bounce pattern
    task simulate_bouncy_press;
        input integer num_bounces;
        input integer total_bounce_time_ns;
        integer i;
        integer bounce_interval;
        begin
            $display("  Simulating %0d bounces over %0d ms",
                     num_bounces, total_bounce_time_ns / 1_000_000);

            bounce_interval = total_bounce_time_ns / (num_bounces * 2);

            // Initial bounces (press)
            for (i = 0; i < num_bounces/2; i = i + 1) begin
                pb_1 = 1;
                #bounce_interval;
                pb_1 = 0;
                #bounce_interval;
            end

            // Stable high period
            pb_1 = 1;
            #(total_bounce_time_ns);

            // Release bounces
            for (i = 0; i < num_bounces/2; i = i + 1) begin
                pb_1 = 0;
                #bounce_interval;
                pb_1 = 1;
                #bounce_interval;
            end

            // Final release
            pb_1 = 0;
        end
    endtask

    // Simulate short glitch (should be filtered out)
    task simulate_glitch;
        input integer duration_ns;
        begin
            $display("  Simulating %0d us glitch", duration_ns / 1000);
            pb_1 = 1;
            #duration_ns;
            pb_1 = 0;
        end
    endtask

    // Verify pulse count
    task verify_pulse_count;
        input integer expected;
        input [255*8:1] test_description;
        begin
            $display("  Expected pulses: %0d", expected);
            $display("  Actual pulses:   %0d", pulse_count);

            if (pulse_count == expected) begin
                $display("  Status: PASS ✓\n");
                pass_count = pass_count + 1;
            end else begin
                $display("  Status: FAIL ✗");
                $display("  %s", test_description);
                $display("  Debug: pb_1=%b, pb_out=%b, Q0=%b, Q1=%b, Q2=%b\n",
                         pb_1, pb_out, dut.Q0, dut.Q1, dut.Q2);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Measure slow clock frequency
    task measure_slow_clock;
        time first_edge, second_edge;
        begin
            $display("  Measuring slow_clk frequency...");

            // Wait for rising edge
            @(posedge dut.slow_clk);
            first_edge = $time;

            // Wait for next rising edge
            @(posedge dut.slow_clk);
            second_edge = $time;

            slow_clk_period = second_edge - first_edge;
            measured_freq = 1_000_000_000.0 / slow_clk_period;  // Hz

            $display("  Measured period: %0d ns (%.1f ms)",
                     slow_clk_period, slow_clk_period / 1_000_000.0);
            $display("  Measured frequency: %.1f Hz", measured_freq);
        end
    endtask

    // Verify clock frequency is within acceptable range
    task verify_clock_frequency;
        real expected_freq;
        real freq_error;
        real freq_tolerance;
        begin
            expected_freq = 400.0;  // 400 Hz
            freq_tolerance = 5.0;   // ±5 Hz tolerance

            freq_error = measured_freq - expected_freq;

            $display("  Expected frequency: %.1f Hz (±%.1f Hz)",
                     expected_freq, freq_tolerance);

            if ((measured_freq >= expected_freq - freq_tolerance) &&
                (measured_freq <= expected_freq + freq_tolerance)) begin
                $display("  Status: PASS ✓\n");
                pass_count = pass_count + 1;
            end else begin
                $display("  Status: FAIL ✗");
                $display("  Frequency error: %.1f Hz\n", freq_error);
                fail_count = fail_count + 1;
            end
        end
    endtask

endmodule
