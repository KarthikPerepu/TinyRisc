`timescale 1ns/1ps

module tb_totalprocessor();
    // Test bench signals
    reg [31:0] a, b;
    reg isAdd, isSub, isCmp, isMul, isDiv, isMod;
    reg isOr, isNot, isAnd, isMov;
    reg isAsl, isAsr, isLsr, isLsl;
    reg isSt, isLd;
    reg [3:0] rs11, rs22;
    
    wire [31:0] aluResult;
    wire cout, cmp_g, cmp_e;
    
    // For tracking test cases
    integer test_case;
    reg [127:0] operation_name;
    
    // For load/store testing
    reg clk;
    wire [31:0] ldresult;
    
    // Memory module for testing load/store
    memoryaccessunit mem_unit (
        .op2(b),
        .aluResult(aluResult),
        .isLd(isLd),
        .isSt(isSt),
        .clk(clk),
        .ldresult(ldresult)
    );
    
    // Instantiate ALU module
    ALU alu_dut (
        .a(a),
        .b(b),
        .isAdd(isAdd),
        .isSub(isSub),
        .isCmp(isCmp),
        .isMul(isMul),
        .isDiv(isDiv),
        .isMod(isMod),
        .isOr(isOr),
        .isNot(isNot),
        .isAnd(isAnd),
        .isMov(isMov),
        .isAsl(isAsl),
        .isAsr(isAsr),
        .isLsr(isLsr),
        .isLsl(isLsl),
        .isSt(isSt),
        .isLd(isLd),
        .rs11(rs11),
        .rs22(rs22),
        .aluResult(aluResult),
        .cout(cout),
        .cmp_g(cmp_g),
        .cmp_e(cmp_e)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Reset all control signals
    task reset_controls;
        begin
            isAdd = 0; isSub = 0; isCmp = 0; isMul = 0; isDiv = 0; isMod = 0;
            isOr = 0; isNot = 0; isAnd = 0; isMov = 0;
            isAsl = 0; isAsr = 0; isLsr = 0; isLsl = 0;
            isSt = 0; isLd = 0;
            rs11 = 0; rs22 = 0;
        end
    endtask
    
    // Print test results
    task print_result;
        input [127:0] op_name;
        input [31:0] op_a;
        input [31:0] op_b;
        input [31:0] result;
        begin
            $display("Test Case %0d: %s", test_case, op_name);
            $display("a = %0d (0x%h), b = %0d (0x%h)", op_a, op_a, op_b, op_b);
            $display("Result = %0d (0x%h)", result, result);
            
            if (isCmp)
                $display("Comparison Flags: Greater = %b, Equal = %b", cmp_g, cmp_e);
            
            if (isAdd || isSub)
                $display("Carry Out = %b", cout);
        end
    endtask
    
    // Test load/store operations
    task test_load_store;
        input [31:0] addr;
        input [31:0] data;
        begin
            // Test store operation
            reset_controls();
            a = addr; b = data;
            isSt = 1;
            #1; // Small delay for combinational logic to settle
            
            $display("Test Case %0d: STORE", test_case);
            $display("Address = %0d (0x%h), Data = %0d (0x%h)", a, a, b, b);
            test_case = test_case + 1;
            
            // Clock cycle to perform the store
            @(posedge clk); #1;
            
            // Test load operation
            reset_controls();
            a = addr;
            isLd = 1;
            #1; // Small delay for combinational logic to settle
            
            $display("Test Case %0d: LOAD", test_case);
            $display("Address = %0d (0x%h)", a, a);
            $display("Loaded Data = %0d (0x%h)", ldresult, ldresult);
            test_case = test_case + 1;
        end
    endtask
    
    // Main test procedure
    initial begin
        $display("Starting ALU Test Bench");
        test_case = 1;
        reset_controls();
        
        // Test 1: Addition
        operation_name = "ADD";
        a = 32'd15; b = 32'd27;
        isAdd = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 2: Addition with carry
        operation_name = "ADD with Carry";
        a = 32'hFFFFFFFF; b = 32'd1;
        isAdd = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 3: Subtraction
        operation_name = "SUBTRACT";
        a = 32'd100; b = 32'd35;
        isSub = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 4: Subtraction with borrow
        operation_name = "SUBTRACT with Borrow";
        a = 32'd10; b = 32'd20;
        isSub = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 5: Compare (Equal)
        operation_name = "COMPARE (Equal)";
        a = 32'd45; b = 32'd45;
        isCmp = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 6: Compare (Greater)
        operation_name = "COMPARE (Greater)";
        a = 32'd75; b = 32'd45;
        isCmp = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 7: Compare (Less)
        operation_name = "COMPARE (Less)";
        a = 32'd30; b = 32'd45;
        isCmp = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 8: Multiplication
        operation_name = "MULTIPLY";
        a = 32'd12; b = 32'd5;
        isMul = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 9: Division
        operation_name = "DIVIDE";
        a = 32'd100; b = 32'd8;
        isDiv = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 10: Modulus
        operation_name = "MODULUS";
        a = 32'd100; b = 32'd8;
        isMod = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 11: Logical OR
        operation_name = "LOGICAL OR";
        a = 32'hAA55; b = 32'h55AA;
        isOr = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 12: Logical AND
        operation_name = "LOGICAL AND";
        a = 32'hAA55; b = 32'h55AA;
        isAnd = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 13: Logical NOT
        operation_name = "LOGICAL NOT";
        a = 32'hAA55; b = 32'h0000;
        isNot = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 14: Move
        operation_name = "MOVE";
        a = 32'd0; b = 32'h12345678;
        isMov = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 15: Logical Shift Left
        operation_name = "LOGICAL SHIFT LEFT";
        a = 32'h00001234; b = 32'd8;
        isLsl = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 16: Logical Shift Right
        operation_name = "LOGICAL SHIFT RIGHT";
        a = 32'h12340000; b = 32'd8;
        isLsr = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 17: Arithmetic Shift Right (positive number)
        operation_name = "ARITHMETIC SHIFT RIGHT (positive)";
        a = 32'h12340000; b = 32'd8;
        isAsr = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 18: Arithmetic Shift Right (negative number)
        operation_name = "ARITHMETIC SHIFT RIGHT (negative)";
        a = 32'h80000000; b = 32'd4;
        isAsr = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Test 19-20: Load/Store test
        test_load_store(32'd100, 32'hDEADBEEF);
        
        // Test 21-22: Load/Store test (different address)
        test_load_store(32'd200, 32'h12345678);
        
        // Additional test: Large shift amount
        operation_name = "LARGE SHIFT (>32 bits)";
        a = 32'h12345678; b = 32'd40;
        isLsr = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        // Additional test: Edge case for division
        operation_name = "DIVISION (by zero)";
        a = 32'd100; b = 32'd0;
        isDiv = 1;
        #5;
        print_result(operation_name, a, b, aluResult);
        test_case = test_case + 1;
        reset_controls();
        
        $display("\nALU Test Bench Completed!\n");
        $finish;
    end
    
    // Monitor for any X/Z values in results
    always @(aluResult) begin
        if (^aluResult === 1'bx || ^aluResult === 1'bz) begin
            $display("WARNING: ALU Result contains X or Z values at time %t", $time);
        end
    end
    
endmodule
