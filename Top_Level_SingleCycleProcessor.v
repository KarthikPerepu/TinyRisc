module Processor (
  input  wire clk,
  input  wire rst
);
  // Fetch
  wire        isBranchTaken;
  wire [31:0] branchPC, instruction, pc;

  instructionfetch IF (
    .clk(clk), .rst(rst),
    .isbranchtaken(isBranchTaken),
    .branchpc(branchPC),
    .instruct(instruction),
    .lo(pc)
  );

  // Control
  wire isSt, isLd, isBeq, isBgt, isRet;
  wire isImmediate, isWb, isUbranch, isCall;
  wire isAdd, isSub, isCmp;
  wire isMul, isDiv, isMod;
  wire isLsl, isLsr, isAsr;
  wire isOr, isAnd, isNot, isMov;
  control_unit CU (
    .inst(instruction),
    .isSt(isSt), .isLd(isLd), .isBeq(isBeq), .isBgt(isBgt), .isRet(isRet),
    .isImmediate(isImmediate), .isWb(isWb), .isUbranch(isUbranch), .isCall(isCall),
    .isAdd(isAdd), .isSub(isSub), .isCmp(isCmp),
    .isMul(isMul), .isDiv(isDiv), .isMod(isMod),
    .isLsl(isLsl), .isLsr(isLsr), .isAsr(isAsr),
    .isOr(isOr), .isAnd(isAnd), .isNot(isNot), .isMov(isMov)
  );

  // Operand Fetch
  wire [3:0] rd = instruction[25:22],
             rs1 = instruction[21:18],
             rs2  = instruction[17:14],
             ra  = 4'd15;
  wire [3:0] inp1, inp2;
  wire [31:0] outreg1, outreg2;

  OperandFetchUnit OFU (
    .isRet(isRet), .isSt(isSt),
    .rs1(rs1), .rs2(rs2), .rd(rd), .ra(ra),
    .inpregfile1(inp1), .inpregfile2(inp2)
  );

  // Register File
  wire [31:0] writedata;
  wire [3:0]  writeadd;
  wire        wr_enable = isWb;
  
  Register_file RF (
    .clock(clk), .reset(rst),
    .reg_rd1(inp1), .reg_rd2(inp2),
    .reg_rd1_out(outreg1), .reg_rd2_out(outreg2),
    .reg_wr1(writeadd), .reg_wr1_data(writedata),
    .wr1_enable(wr_enable)
  );

  // Immediate & ALU
  wire [31:0] immx, branchTarget, aluB, aluResult;
  wire cout, cmp_g, cmp_e;

  imm_gen IG (
    .inst(instruction),
    .immx(immx),
    .pc(pc),
    .branchTarget(branchTarget)
  );

  mux2x1 #(.w(32)) imm_mux (
    .a(outreg2),
    .b(immx),
    .sel(isImmediate),
    .o(aluB)
  );

  ALU alu_unit (
    .a(outreg1), .b(aluB),
    .isAdd(isAdd), .isSub(isSub), .isCmp(isCmp),
    .isMul(isMul), .isDiv(isDiv), .isMod(isMod),
    .isOr(isOr), .isNot(isNot), .isAnd(isAnd), .isMov(isMov),
    .isAsl(isLsl), .isAsr(isAsr), .isLsr(isLsr), .isLsl(isLsl),.isLd(isLd),.isSt(isSt),
    .aluResult(aluResult), .cout(cout), .cmp_g(cmp_g), .cmp_e(cmp_e)
  );
  wire ocmp_g,ocmp_e;
flag_reg flgreg(
.clk(clk),
.isCmp(isCmp),
.cmp_g(cmp_g),
.cmp_e(cmp_e),
.ocmp_e(ocmp_e),
.ocmp_g(ocmp_g)
);

  wire [1:0] flag={ocmp_g,ocmp_e};
  branchunit BU (
    .branchTarget  (branchTarget),
    .op1           (outreg1),
    .isBeq         (isBeq),
    .isBgt         (isBgt),
    .isUbranch     (isUbranch),
    .flag          (flag),
    .isRet         (isRet),
    .branchPC      (branchPC),
    .isBranchTaken (isBranchTaken),
    .isCall(isCall)
  );

  wire [31:0] ldResult;
  memoryaccessunit MAU (
    .op2(outreg2), .aluResult(aluResult),
    .isLd(isLd), .isSt(isSt),
    .clk(clk),
    .ldresult(ldResult)
  );

  regwriteback RW (
    .aluResult(aluResult),
    .ldResult(ldResult),
    .prpc(pc + 32'd4),
    .isLd(isLd), .isCall(isCall), .isWb(isWb),
    .ra(ra), .rd(rd),
    .writedata(writedata),
    .writeadd(writeadd)
  );

endmodule
