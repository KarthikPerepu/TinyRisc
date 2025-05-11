module control_unit (
  input  wire [31:0] inst,
  output reg         isSt,
  output reg         isLd,
  output reg         isBeq,
  output reg         isBgt,
  output reg         isRet,
  output reg         isImmediate,
  output reg         isWb,
  output reg         isUbranch,
  output reg         isCall,
  output reg         isAdd,
  output reg         isSub,
  output reg         isCmp,
  output reg         isMul,
  output reg         isDiv,
  output reg         isMod,
  output reg         isLsl,
  output reg         isLsr,
  output reg         isAsr,
  output reg         isOr,
  output reg         isAnd,
  output reg         isNot,
  output reg         isMov
);
  wire op1 = inst[27];
  wire op2 = inst[28];
  wire op3 = inst[29];
  wire op4 = inst[30];
  wire op5 = inst[31];

  always @(*) begin
    isSt        = ~op5 &  op4 &  op3 &  op2 &  op1;
    isLd        = ~op5 &  op4 &  op3 &  op2 & ~op1;
    isBeq       =  op5 & ~op4 & ~op3 & ~op2 & ~op1;
    isBgt       =  op5 & ~op4 & ~op3 & ~op2 &  op1;
    isRet       =  op5 & ~op4 &  op3 & ~op2 & ~op1;
    isImmediate =  inst[26];
     isWb=(~(op5|((~op5)&op3&op1&(op4|(~op2))))|(op5&(~op4)&(~op3)&op2&op1));
    isUbranch   =  op5 & ~op4 & ((~op3 & op2) | (op3 & ~op2 & ~op1));
    isCall      =  op5 & ~op4 & ~op3 &  op2 &  op1;
      isAdd =(((~op5) & (~op4) & (~op3) & (~op2) & (~op1)) | ((~op5) & op4 & op3 & op2));
    isSub       = ~op5 & ~op4 & ~op3 & ~op2 &  op1;
    isCmp       = ~op5 & ~op4 &  op3 & ~op2 &  op1;
    isMul       = ~op5 & ~op4 & ~op3 &  op2 & ~op1;
    isDiv       = ~op5 & ~op4 & ~op3 &  op2 &  op1;
    isMod       = ~op5 & ~op4 &  op3 & ~op2 & ~op1;
    isLsl       = ~op5 &  op4 & ~op3 &  op2 & ~op1;
    isLsr       = ~op5 &  op4 & ~op3 &  op2 &  op1;
    isAsr       = ~op5 &  op4 &  op3 & ~op2 & ~op1;
    isOr        = ~op5 & ~op4 &  op3 &  op2 &  op1;
    isAnd       = ~op5 & ~op4 &  op3 &  op2 & ~op1;
    isNot       = ~op5 &  op4 & ~op3 & ~op2 & ~op1;
    isMov       = ~op5 &  op4 & ~op3 & ~op2 &  op1;
  end
endmodule
