module tt_um_dranoel06_SAP1 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);



assign uio_oe = 8'b01000000; 
assign uio_out[7:7] = 1'b0;     
assign uio_out[5:0] = 6'b0;

wire _ena_unused = ena;
wire [2:0] uio_un_unused = uio_in[6:4]; 
wire tx_en;

cpu cpu0(
    .clk(clk),
    .reset(~rst_n),
    .programm_input(ui_in),
    .output_register(uo_out),
    .prog(uio_in[7]),
    .addr(uio_in[3:0]),
    .tx_en(tx_en)

);

uart_tx uart0(
    .clk(clk),
    .reset(~rst_n),
    .tx_en(tx_en),
    .data(uo_out),
    .tx(uio_out[6])
);


endmodule