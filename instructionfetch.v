module instructionfetch (
  input  wire        clk,
  input  wire        rst,
  input  wire        isbranchtaken,
  input  wire [31:0] branchpc,
  output wire [31:0] instruct,
  output reg  [31:0] lo
);
  reg  [7:0] instrumem [0:255];
  wire [31:0] next_pc;

  mux2x1 #(.w(32)) pc_mux (
    .a(lo + 32'd4),
    .b(branchpc),
    .sel(isbranchtaken),
    .o(next_pc)
  );

  always @(posedge clk or posedge rst) begin
    if (rst)   lo <= 32'd0;
    else       lo <= next_pc;
  end

  assign instruct = {
    instrumem[lo],
    instrumem[lo+1],
    instrumem[lo+2],
    instrumem[lo+3]
  };
endmodule
