module uart_tx (
    input wire clk,
    input wire reset,
    input wire tx_en,
    input wire [7:0] data,
    output reg tx
);

parameter STATE_IDLE = 2'b00;
parameter STATE_START = 2'b01;
parameter STATE_SEND = 2'b10;
parameter STATE_STOP = 2'b11;

reg[1:0] uart_state;
reg[3:0] bit_counter;
reg tx_en_prev;

always @(posedge clk) begin

    if (reset == 1'b1) begin     
        uart_state <= STATE_IDLE;
        tx <= 1;
        bit_counter <= 4'b0;
        tx_en_prev <= 1'b0;
    end

    else begin
        tx_en_prev <= tx_en;
        if (uart_state == STATE_IDLE) begin
            tx <= 1'b1;
            if (tx_en == 1'b1 && tx_en != tx_en_prev ) begin
                uart_state <= STATE_START;
            end
        end

        else if (uart_state == STATE_START) begin
            tx <= 1'b0;
            uart_state <= STATE_SEND;
        end

        else if (uart_state == STATE_SEND) begin
            tx <= data[bit_counter[2:0]];
            bit_counter <= bit_counter + 1'b1;

            if (bit_counter == 4'd7) begin
                bit_counter <= 4'd0;
                uart_state <= STATE_STOP;
            end

        end
        else if (uart_state == STATE_STOP) begin
            tx <= 1'b1;
            uart_state <= STATE_IDLE;
        end
    end
end
    
endmodule