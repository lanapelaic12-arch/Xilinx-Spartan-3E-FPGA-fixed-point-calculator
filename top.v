`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:28:41 07/14/2025 
// Design Name: 
// Module Name:    projekt_kalkulator 
// Project Name: 
// Target Devices: 
// Tool versions: 

//////////////////////////////////////////////////////////////////////////////////

module projekt_kalkulator(
    input wire clk,
    input wire rst,
    input wire btn_enter_raw,
    input wire [3:0] sw,
    input wire btn_op_raw,
    input wire btn_frac_raw,
    input wire btn_sign_mode_raw,
    output reg [7:0] led
);
   
    reg [15:0] a, b;                    
    reg [1:0] op = 0;
    reg [3:0] input_stage = 0;
    reg btn_enter_prev = 0;
    reg btn_op_prev = 0;
    reg btn_sign_mode_prev = 0;
    reg signed_mode = 0;                
    wire btn_enter, btn_op, btn_sign_mode;
    reg signed [31:0] result_temp_signed;   
    reg [31:0] result_temp;                
    reg [15:0] result;                       

   
    debounce debounce_enter(
        .pb_1(btn_enter_raw),
        .clk(clk),
        .pb_out(btn_enter)
    );

    debounce debounce_op(
        .pb_1(btn_op_raw),
        .clk(clk),
        .pb_out(btn_op)
    );

    debounce debounce_sign_mode(
        .pb_1(btn_sign_mode_raw),
        .clk(clk),
        .pb_out(btn_sign_mode)
    );

   
    wire btn_frac;
    debounce_level debounce_frac_level(
        .pb_1(btn_frac_raw),
        .clk(clk),
        .pb_out_level(btn_frac)
    );
    
    
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_enter_prev <= 0;
            btn_op_prev <= 0;
            btn_sign_mode_prev <= 0;
        end else begin
            btn_enter_prev <= btn_enter;
            btn_op_prev <= btn_op;
            btn_sign_mode_prev <= btn_sign_mode;
        end
    end
    
    // Unos Q8.8 brojeva
  
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            input_stage <= 0;
            a <= 16'h0000;  
            b <= 16'h0000; 
        end else if (btn_enter && !btn_enter_prev) begin
            case (input_stage)
                
                4'd0: a[15:12] <= sw;     
                4'd1: a[11:8]  <= sw;     
              
                4'd2: a[7:4]   <= sw;     
                4'd3: a[3:0]   <= sw;     
             
                4'd4: b[15:12] <= sw;     
                4'd5: b[11:8]  <= sw;     
              
                4'd6: b[7:4]   <= sw;     
                4'd7: b[3:0]   <= sw;     
            endcase
            if (input_stage < 8)
                input_stage <= input_stage + 1;
        end
    end
    
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            op <= 0;
        end else if (btn_op && !btn_op_prev) begin
            op <= (op == 2) ? 0 : op + 1;
        end
    end

   
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            signed_mode <= 0; 
        end else if (btn_sign_mode && !btn_sign_mode_prev) begin
            signed_mode <= ~signed_mode;  
        end
    end


    always @(*) begin
        case (op)
            2'b00: begin 
                if (signed_mode) begin
                   
                    result_temp_signed = $signed({a[15], a}) + $signed({b[15], b});

                  
                    if (result_temp_signed > $signed(17'h007FFF)) begin
                        result = 16'h7FFF;  
                    end else if (result_temp_signed < $signed(17'h018000)) begin
                        result = 16'h8000;  
                    end else begin
                        result = result_temp_signed[15:0];
                    end
                end else begin
                   
                    result_temp = {16'd0, a} + {16'd0, b};

                    if (result_temp[16]) begin  
                        result = 16'hFFFF;  
                    end else begin
                        result = result_temp[15:0];
                    end
                end
            end

            2'b01: begin 
                if (signed_mode) begin
                    
                    result_temp_signed = $signed({a[15], a}) - $signed({b[15], b});

               
                    if (result_temp_signed > $signed(17'h007FFF)) begin
                        result = 16'h7FFF;  
                    end else if (result_temp_signed < $signed(17'h018000)) begin
                        result = 16'h8000;  
                    end else begin
                        result = result_temp_signed[15:0];
                    end
                end else begin
                  
                    if (a < b) begin
                        result = 16'h0000;  
                    end else begin
                        result = a - b;
                    end
                end
            end

            2'b10: begin 
                if (signed_mode) begin
                  
                    result_temp_signed = $signed(a) * $signed(b);

                    if (result_temp_signed >>> 8 > $signed(32'h00007FFF)) begin
                        result = 16'h7FFF; 
                    end else if (result_temp_signed >>> 8 < $signed(32'hFFFF8000)) begin
                        result = 16'h8000; 
                    end else begin
                        result = result_temp_signed[23:8];  
                    end
                end else begin
                    
                    result_temp = a * b;  // 16-bit * 16-bit = 32-bit

                 
                    if (result_temp[31:24] != 8'h00) begin
                        result = 16'hFFFF; 
                    end else begin
                        result = result_temp[23:8];
                    end
                end
            end

            default: begin
                result = 16'h0000;
            end
        endcase
    end
    
  
    always @(*) begin
        if (input_stage == 8) begin
            
            if(btn_frac) begin
                led = result[7:0];  
            end else begin
                led = result[15:8]; 
            end
        end else begin
           
            led = {signed_mode, 3'b000, sw};  
        end
    end
    
endmodule