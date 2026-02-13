module cpu(
    input wire clk, reset, prog, 
    output reg[7:0] output_register, 
    input wire[7:0] programm_input, 
    input wire [3:0] addr
);

// Intruction Defintion
parameter LDA = 4'b0001;
parameter ADD = 4'b0010;
parameter OUT = 4'b0011;
parameter JMP = 4'b0100;
parameter STA = 4'b0101;
parameter LDI = 4'b0110; 
parameter SUB = 4'b0111;
parameter BEQ = 4'b1000; 
parameter CMP = 4'b1001;

//Control Signals
reg pc_in;
reg pc_out;
reg pc_add;
reg mar_in;
reg ram_in;
reg ram_out;
reg ir_in;
reg ir_out; 
reg a_in;
reg a_imm_in;
reg a_out;
reg b_in;
reg b_out;
reg output_in;
reg alu_op;
reg alu_out;

//Registers
reg[2:0] step;
reg[3:0] pc;
reg[3:0] mar;
reg[7:0] ram[0:15];
reg[7:0] ir;
reg[7:0] a_reg;
reg[7:0] b_reg;
reg zero_flag;

// Bus
wire[7:0] bus;
assign bus = 
    pc_out ? {4'b0000, pc} :
    ram_out ? ram[mar] :
    ir_out ? {4'b000, ir[3:0]} :
    a_out ? a_reg :
    b_out ? b_reg :
    alu_out ? alu :
    8'b0;

always @(posedge clk) begin
    
// Instruction Step Counter
    if (reset == 1'b1) begin
        step <= 3'd0;
    end
    else if (step > 3'd6) begin
        step <= 3'd1;
    end 
    else begin
        step <= step + 3'd1;
    end

// Programm Counter
    if (reset == 1'b1) begin
        pc <= 4'b0000;
    end
    else if (pc_add) begin
        pc <= pc + 1'b1;
    end
    else if (pc_in) begin 
        pc <= {bus[3:0]};
    end
    
// Memory Adress Register
    if (reset == 1'b1) begin
        mar <= 4'b0000;
    end
    else if (mar_in) begin
        mar <= bus[3:0];      
    end 

//RAM
    if (prog == 1'b1) begin
        ram[addr] <= programm_input;
    end
    else if (ram_in && ~reset) begin
        ram[mar] <= bus;
    end

//Instruction Register
    if (reset == 1'b1) begin
        ir <= 8'b0000000;
    end
    else if (ir_in) begin
        ir <= bus;
    end

//Output Register
    if (reset) begin
        output_register <= 8'b0;
    end
    else if (output_in) begin
        output_register <= bus;
    end    

//A Register
    if (reset) begin
        a_reg <= 8'b0;
    end
    else if (a_in) begin
        a_reg <= bus;
    end
    else if (a_imm_in) begin
        a_reg <= {4'b0, bus[3:0]};
    end
    
//B Register
    if (reset) begin
        b_reg <= 8'b0;
    end
    else if (b_in) begin
        b_reg <= bus;
    end

// Zero Flag
    if (reset == 1'b1) begin
        zero_flag <= 1'b0;
    end
    else if ((step == 3'd6 && (ir[7:4] == ADD || ir[7:4] == SUB)) ||  (step == 3'd5 && ir[7:4] == CMP)) begin
        zero_flag <= (alu == 8'b00000000);
    end

end

//ALU
wire [7:0] alu;
assign alu = alu_op ? (a_reg - b_reg) : (a_reg + b_reg);

//Control Unit
always @(*) begin

    pc_in     = 1'b0;
    pc_out    = 1'b0; 
    pc_add    = 1'b0;
    mar_in    = 1'b0;
    ram_in    = 1'b0;
    ram_out   = 1'b0;
    ir_in     = 1'b0;
    ir_out    = 1'b0;
    a_in      = 1'b0;
    a_imm_in  = 1'b0;
    a_out     = 1'b0;
    b_in      = 1'b0;
    b_out     = 1'b0;
    alu_out   = 1'b0;
    alu_op    = 1'b0;
    output_in = 1'b0;

    if (reset == 1'b0) begin
        
        if (step == 3'd1) begin // Fetch
            pc_out = 1'b1;
            mar_in = 1'b1;
        end
        else if (step == 3'd2) begin
            ram_out = 1'b1;
            ir_in   = 1'b1;
            pc_add  = 1'b1;
        end  
        
        else if (ir[7:4] == ADD) begin // ADD
            if (step == 3'd3) begin
                ir_out = 1'b1;
                mar_in = 1'b1;
            end
            else if (step == 3'd4) begin
                ram_out = 1'b1;
                b_in    = 1'b1;
            end
            else if (step == 3'd6) begin
                alu_out = 1'b1;
                alu_op  = 1'b0;
                a_in    = 1'b1;
            end       
        end
        
        else if (ir[7:4] == SUB) begin // SUB
            if (step == 3'd3) begin
                ir_out = 1'b1;
                mar_in = 1'b1;
            end
            else if (step == 3'd4) begin
                ram_out = 1'b1;
                b_in    = 1'b1;
            end
            else if (step == 3'd6) begin
                alu_op  = 1'b1;
                alu_out = 1'b1;
                a_in    = 1'b1;
            end       
        end

        else if (ir[7:4] == LDA) begin // LDA
            if (step == 3'd3) begin
                ir_out = 1'b1;
                mar_in = 1'b1;
            end
            else if (step == 3'd4) begin
                ram_out = 1'b1;
                a_in    = 1'b1;
            end
        end

        else if (ir[7:4] == LDI) begin // LDI
            if (step == 3'd3) begin
                ir_out   = 1'b1;
                a_imm_in = 1'b1;
            end
        end

        else if (ir[7:4] == STA) begin // STA
            if (step == 3'd3) begin
                ir_out = 1'b1;
                mar_in = 1'b1;
            end
            else if (step == 3'd4) begin
                a_out  = 1'b1;
                ram_in = 1'b1;
            end
        end

        else if (ir[7:4] == OUT) begin // OUT
            if (step == 3'd3) begin
                a_out     = 1'b1;
                output_in = 1'b1;
            end
        end

        else if (ir[7:4] == JMP) begin // JMP
            if (step == 3'd3) begin
                ir_out = 1'b1;
                pc_in  = 1'b1;
            end
        end

        else if (ir[7:4] == BEQ) begin // BEQ
            if (step == 3'd3) begin
                if (zero_flag == 1'b1) begin
                    ir_out = 1'b1;
                    pc_in  = 1'b1;
                end        
            end
        end

        else if (ir[7:4] == CMP) begin // CMP
            if (step == 3'd3) begin
                ir_out = 1'b1;
                mar_in = 1'b1;
            end
            else if (step == 3'd4) begin
                ram_out = 1'b1;
                b_in    = 1'b1;
            end
            else if (step == 3'd5) begin
                alu_op = 1'b1;
            end
        end

    end
end

endmodule
