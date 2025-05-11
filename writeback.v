module regwriteback (
  input  wire [31:0] aluResult,
  input  wire [31:0] ldResult,
  input  wire [31:0] prpc,
  input  wire        isLd, isCall, isWb,
  input  wire [3:0]  ra, rd,
  output wire [3:0]  writeadd,
  output wire [31:0] writedata
);
  wire [1:0] sel = {isCall, isLd};

  mux4x1 #(.w(32)) wb_mux (
    .a(aluResult),
    .b(ldResult),
    .c(prpc),
    .d(32'd0),
    .en(isWb),
    .sel(sel),
    .o(writedata)
  );
  mux2x1 #(.w(4)) addr_mux (
    .a(rd),
    .b(ra),
    .sel(isCall),
    .o(writeadd)
  );
endmodule

