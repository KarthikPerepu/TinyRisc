module memoryaccessunit (
  input  wire [31:0] op2,
  input  wire [31:0] aluResult,
  input  wire        isLd, isSt,
  input  wire        clk,
  output wire [31:0] ldresult
);
  reg [31:0] datamemory [0:1023];
  reg [31:0] mdr;

  // Make load operations combinational instead of sequential
  assign ldresult = isLd ? datamemory[aluResult] : 32'd0;

  // Store operations remain sequential (on clock edge)
  always @(posedge clk) begin
    if (isSt) datamemory[aluResult] <= op2;
  end 
endmodule
