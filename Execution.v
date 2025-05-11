//9) ALU Submodules
module fulladder (
  input  wire a, b, cin,
  output wire s, cout
);
  assign s    = a ^ b ^ cin;
  assign cout = (a & b) | (b & cin) | (cin & a);
endmodule

module adder_subtractor (
  input  wire [31:0] a, b,
  input  wire        s,
  output wire [31:0] sum,
  output wire        cout
);
  wire [31:0] bm = b ^ {32{s}};
  wire [32:0] c;
  assign c[0] = s;
  genvar i;
  generate
    for (i=0; i<32; i=i+1) begin
      fulladder fa (
        .a(a[i]), .b(bm[i]), .cin(c[i]),
        .s(sum[i]), .cout(c[i+1])
      );
    end
  endgenerate
  assign cout = c[32];
endmodule

module muxx4x1 #(
  parameter W=1
)(
     input  wire [W-1:0] a,        
    input  wire [W-1:0] b,
    input  wire [W-1:0] c,
    input  wire [W-1:0] d,
    input  wire        e,       
    input  wire [1:0]  sel,      
    output reg  [W-1:0] o   
);
    always @(*) begin
    if(e) begin
      case (sel)
        2'b00: o = a;
        2'b01: o = b;
        2'b10: o = c;
        2'b11: o = d;
        default: o = {W{1'b0}};
      endcase
    end else begin
      o = {W{1'b0}}; 
    end
end

endmodule

module Adder (
  input  wire [31:0] a, b,
  input  wire        isAdd, isSub, isCmp, isLd, isSt,
  output wire [31:0] sum,
  output wire        cout, cmp_g, cmp_e
);
  // Determine operation type
  wire [1:0] op = isAdd ? 2'b01
                : isSub ? 2'b10
                : isCmp ? 2'b11
                : 2'b00;
  wire sub_ctrl = op[1];
  wire [31:0] mid;
  wire        mid_c;
  
  // Perform addition/subtraction
  adder_subtractor u0(.a(a), .b(b), .s(sub_ctrl), .sum(mid), .cout(mid_c));

  // Critical fix: For load/store, pass through the address value 
  // even when op is 2'b00
  assign sum   = (isLd || isSt) ? a : (op != 2'b00) ? mid : 32'd0;
  assign cout  = (op != 2'b00) ? mid_c : 1'b0;

  // Comparison outputs are enabled only for the compare operation
  assign cmp_g = (op == 2'b11) ? ~mid[31]      : 1'b0;
  assign cmp_e = (op == 2'b11) ? ~(|(a ^ b))   : 1'b0;
endmodule

module Mul (
  input  wire [31:0] a, b,
  input  wire        isMul,
  output wire [31:0] mo
);
  assign mo = isMul ? a * b : 32'd0;
endmodule

module Divider (
  input  wire [31:0] a, b,
  input  wire        isDiv, isMod,
  output wire [31:0] o
);
  assign o = isDiv ? (a / b) : isMod ? (a % b) : 32'd0;
endmodule

module Logical_unit (
  input  wire [31:0] a, b,
  input  wire        isOr, isNot, isAnd,
  output wire [31:0] o
);
  assign o = isOr  ? (a | b)
           : isNot ? (~a)
           : isAnd ? (a & b)
           : 32'd0;
endmodule

module Mov (
  input  wire [31:0] b,
  input  wire        isMov,
  output wire [31:0] o
);
  assign o = isMov ? b : 32'd0;
endmodule

module unified_shift_register (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        isAsl,
    input  wire        isAsr,
    input  wire        isLsl,
    input  wire        isLsr,
    output wire [31:0] o
);

  // determine shift type: 00=asl, 01=asr, 10=lsr, 11=lsl
  wire [1:0] s = isAsl ? 2'b00 :
                 isAsr ? 2'b01 :
                 isLsr ? 2'b10 :
                 isLsl ? 2'b11 :
                         2'b00;
                       
  // Original sign bit for ASR operations - this remains constant throughout all stages
  wire sign_bit = a[31];

  genvar i;

  // 16-bit stage
  wire [31:0] shifted16;
  generate
    for (i = 0; i < 32; i = i + 1) begin : stage16_compute
      if (i < 16) begin
        // Lower bits - shifted data comes from higher bits
        muxx4x1 #(.W(1)) u_mux16 (
          .a(1'b0),                 // ASL - fill with 0
          .b(i+16 < 32 ? a[i+16] : sign_bit), // ASR - data from upper half with sign ext
          .c(i+16 < 32 ? a[i+16] : 1'b0),     // LSR - data from upper half with 0 ext
          .d(1'b0),                 // LSL - fill with 0
          .e(1'b1),
          .sel(s),
          .o(shifted16[i])
        );
      end else begin
        // Upper bits - may need sign extension for ASR
        muxx4x1 #(.W(1)) u_mux16 (
          .a(1'b0),                 // ASL - fill with 0
          .b(s == 2'b01 ? sign_bit : 1'b0), // ASR - sign extend all upper bits
          .c(1'b0),                 // LSR - fill with 0
          .d(i-16 < 16 ? a[i-16] : 1'b0), // LSL - data from lower half
          .e(1'b1),
          .sel(s),
          .o(shifted16[i])
        );
      end
    end
  endgenerate

  // select between original or 16-bit shifted
  wire [31:0] shift_16_f;
  mux2x1 #(.w(32)) mux16_sel (
    .a(a), .b(shifted16), .sel(b[4]), .o(shift_16_f)
  );

  // 8-bit stage
  wire [31:0] shifted8;
  generate
    for (i = 0; i < 32; i = i + 1) begin : stage8_compute
      if (i < 8) begin
        // Lower bits - shifted data comes from higher bits
        muxx4x1 #(.W(1)) u_mux8 (
          .a(1'b0),                  // ASL - fill with 0
          .b(i+8 < 32 ? shift_16_f[i+8] : sign_bit), // ASR with sign ext
          .c(i+8 < 32 ? shift_16_f[i+8] : 1'b0),     // LSR with 0 ext
          .d(1'b0),                  // LSL - fill with 0
          .e(1'b1),
          .sel(s),
          .o(shifted8[i])
        );
      end else if (i < 24) begin
        // Middle bits - normal shifting
        muxx4x1 #(.W(1)) u_mux8 (
          .a(shift_16_f[i-8]),       // ASL - data from lower section
          .b(i+8 < 32 ? shift_16_f[i+8] : sign_bit), // ASR with sign ext
          .c(i+8 < 32 ? shift_16_f[i+8] : 1'b0),     // LSR with 0 ext
          .d(shift_16_f[i-8]),       // LSL - data from lower section
          .e(1'b1),
          .sel(s),
          .o(shifted8[i])
        );
      end else begin
        // Upper bits - may need sign extension for ASR
        muxx4x1 #(.W(1)) u_mux8 (
          .a(shift_16_f[i-8]),       // ASL - data from lower section
          .b(s == 2'b01 ? sign_bit : 1'b0), // ASR - sign extend
          .c(1'b0),                  // LSR - fill with 0
          .d(shift_16_f[i-8]),       // LSL - data from lower section
          .e(1'b1),
          .sel(s),
          .o(shifted8[i])
        );
      end
    end
  endgenerate

  // select between 16-stage or 8-stage
  wire [31:0] shift_8_f;
  mux2x1 #(.w(32)) mux8_sel (
    .a(shift_16_f), .b(shifted8), .sel(b[3]), .o(shift_8_f)
  );

  // 4-bit stage
  wire [31:0] shifted4;
  generate
    for (i = 0; i < 32; i = i + 1) begin : stage4_compute
      if (i < 4) begin
        // Lower bits - shifted data comes from higher bits
        muxx4x1 #(.W(1)) u_mux4 (
          .a(1'b0),                 // ASL - fill with 0
          .b(i+4 < 32 ? shift_8_f[i+4] : sign_bit), // ASR with sign ext
          .c(i+4 < 32 ? shift_8_f[i+4] : 1'b0),     // LSR with 0 ext
          .d(1'b0),                 // LSL - fill with 0
          .e(1'b1),
          .sel(s),
          .o(shifted4[i])
        );
      end else if (i < 28) begin
        // Middle bits - normal shifting
        muxx4x1 #(.W(1)) u_mux4 (
          .a(shift_8_f[i-4]),       // ASL - data from lower section
          .b(i+4 < 32 ? shift_8_f[i+4] : sign_bit), // ASR with sign ext
          .c(i+4 < 32 ? shift_8_f[i+4] : 1'b0),     // LSR with 0 ext
          .d(shift_8_f[i-4]),       // LSL - data from lower section
          .e(1'b1),
          .sel(s),
          .o(shifted4[i])
        );
      end else begin
        // Upper bits - may need sign extension for ASR
        muxx4x1 #(.W(1)) u_mux4 (
          .a(shift_8_f[i-4]),       // ASL - data from lower section
          .b(s == 2'b01 ? sign_bit : 1'b0), // ASR - sign extend
          .c(1'b0),                 // LSR - fill with 0
          .d(shift_8_f[i-4]),       // LSL - data from lower section
          .e(1'b1),
          .sel(s),
          .o(shifted4[i])
        );
      end
    end
  endgenerate

  // select between 8-stage or 4-stage
  wire [31:0] shift_4_f;
  mux2x1 #(.w(32)) mux4_sel (
    .a(shift_8_f), .b(shifted4), .sel(b[2]), .o(shift_4_f)
  );

  // 2-bit stage
  wire [31:0] shifted2;
  generate
    for (i = 0; i < 32; i = i + 1) begin : stage2_compute
      if (i < 2) begin
        // Lower bits - shifted data comes from higher bits
        muxx4x1 #(.W(1)) u_mux2 (
          .a(1'b0),                 // ASL - fill with 0
          .b(i+2 < 32 ? shift_4_f[i+2] : sign_bit), // ASR with sign ext
          .c(i+2 < 32 ? shift_4_f[i+2] : 1'b0),     // LSR with 0 ext
          .d(1'b0),                 // LSL - fill with 0
          .e(1'b1),
          .sel(s),
          .o(shifted2[i])
        );
      end else if (i < 30) begin
        // Middle bits - normal shifting
        muxx4x1 #(.W(1)) u_mux2 (
          .a(shift_4_f[i-2]),       // ASL - data from lower section
          .b(i+2 < 32 ? shift_4_f[i+2] : sign_bit), // ASR with sign ext
          .c(i+2 < 32 ? shift_4_f[i+2] : 1'b0),     // LSR with 0 ext
          .d(shift_4_f[i-2]),       // LSL - data from lower section
          .e(1'b1),
          .sel(s),
          .o(shifted2[i])
        );
      end else begin
        // Upper bits - may need sign extension for ASR
        muxx4x1 #(.W(1)) u_mux2 (
          .a(shift_4_f[i-2]),       // ASL - data from lower section
          .b(s == 2'b01 ? sign_bit : 1'b0), // ASR - sign extend
          .c(1'b0),                 // LSR - fill with 0
          .d(shift_4_f[i-2]),       // LSL - data from lower section
          .e(1'b1),
          .sel(s),
          .o(shifted2[i])
        );
      end
    end
  endgenerate

  // select between 4-stage or 2-stage
  wire [31:0] shift_2_f;
  mux2x1 #(.w(32)) mux2_sel (
    .a(shift_4_f), .b(shifted2), .sel(b[1]), .o(shift_2_f)
  );

  // 1-bit stage
  wire [31:0] shifted1;
  generate
    for (i = 0; i < 32; i = i + 1) begin : stage1_compute
      if (i < 1) begin
        // Lowest bit - shifted data comes from higher bits
        muxx4x1 #(.W(1)) u_mux1 (
          .a(1'b0),                 // ASL - fill with 0
          .b(i+1 < 32 ? shift_2_f[i+1] : sign_bit), // ASR with sign ext
          .c(i+1 < 32 ? shift_2_f[i+1] : 1'b0),     // LSR with 0 ext
          .d(1'b0),                 // LSL - fill with 0
          .e(1'b1),
          .sel(s),
          .o(shifted1[i])
        );
      end else if (i < 31) begin
        // Middle bits - normal shifting
        muxx4x1 #(.W(1)) u_mux1 (
          .a(shift_2_f[i-1]),       // ASL - data from lower section
          .b(i+1 < 32 ? shift_2_f[i+1] : sign_bit), // ASR with sign ext
          .c(i+1 < 32 ? shift_2_f[i+1] : 1'b0),     // LSR with 0 ext
          .d(shift_2_f[i-1]),       // LSL - data from lower section
          .e(1'b1),
          .sel(s),
          .o(shifted1[i])
        );
      end else begin
        // MSB - may need sign extension for ASR
        muxx4x1 #(.W(1)) u_mux1 (
          .a(shift_2_f[i-1]),       // ASL - data from lower section
          .b(s == 2'b01 ? sign_bit : 1'b0), // ASR - sign extend with original sign bit
          .c(1'b0),                 // LSR - fill with 0
          .d(shift_2_f[i-1]),       // LSL - data from lower section
          .e(1'b1),
          .sel(s),
          .o(shifted1[i])
        );
      end
    end
  endgenerate

  // select between 2-stage or 1-stage
  wire [31:0] shift_1_f;
  mux2x1 #(.w(32)) mux1_sel (
    .a(shift_2_f), .b(shifted1), .sel(b[0]), .o(shift_1_f)
  );

  // if shift amount >= 32, result depends on shift type
  wire moreshift = |b[31:5];
  reg [31:0] full_shift;
  
  // Handle shifts >= 32 bits
  integer j;
  always @(*) begin
    for (j = 0; j < 32; j = j + 1) begin
      full_shift[j] = (s == 2'b01) ? sign_bit : 1'b0;
    end
  end
  
  assign o = moreshift ? full_shift : shift_1_f;
endmodule
// 10) Top-level ALU
module ALU (
  input  wire [31:0] a, b,
  input  wire        isAdd, isSub, isCmp,
  input  wire        isMul, isDiv, isMod,
  input  wire        isOr,  isNot, isAnd, isMov,
  input  wire        isAsl, isAsr, isLsr, isLsl,
  input wire         isSt,isLd,
  input [3:0] rs11,rs22,
  output reg  [31:0] aluResult,
  output wire        cout, cmp_g, cmp_e
);
  wire [31:0] add_out, mul_out, div_out, log_out, mov_out, shift_out;
   Adder  u_add(.a(a), .b(b),.isSt(isSt),.isLd(isLd), .isAdd(isAdd), .isSub(isSub), .isCmp(isCmp),
               .sum(add_out), .cout(cout), .cmp_g(cmp_g), .cmp_e(cmp_e));
  Mul    u_mul(.a(a), .b(b), .isMul(isMul), .mo(mul_out));
  Divider u_div(.a(a), .b(b), .isDiv(isDiv), .isMod(isMod), .o(div_out));
  Logical_unit u_log(.a(a), .b(b), .isOr(isOr), .isNot(isNot), .isAnd(isAnd), .o(log_out));
  Mov    u_mov(.b(b), .isMov(isMov), .o(mov_out));
  unified_shift_register u_sh(.a(a), .b(b),
                              .isAsl(isAsl), .isAsr(isAsr),
                              .isLsr(isLsr), .isLsl(isLsl),
                              .o(shift_out));

  always @(*) begin
    case (1'b1)
      isAdd, isSub, isCmp: aluResult = add_out;
      isMul:               aluResult = mul_out;
      isDiv, isMod:        aluResult = div_out;
      isOr, isNot, isAnd:  aluResult = log_out;
      isMov:               aluResult = mov_out;
      isAsl, isAsr, isLsr, isLsl: aluResult = shift_out;
      default:             aluResult = 32'd0;
    endcase
  end
endmodule
// 7) Branch Unit
module branchunit(
    input [31:0] branchTarget,
    input [31:0] op1,
    input isBeq,isBgt,isUbranch,
    input [1:0] flag,
    input isRet,
    input isCall,
    output [31:0] branchPC,
    output isBranchTaken
);
mux2x1 #(.w(32)) m1 (
    .a(branchTarget),
    .b(op1),
    .sel(isRet),
    .o(branchPC)
);
wire fa,sa;
assign fa=isBeq&flag[0];
assign sa=isBgt&flag[1];
assign isBranchTaken=isUbranch|fa|sa|isCall;
endmodule
