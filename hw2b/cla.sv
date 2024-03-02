// Vedant Kelkar - vkelkar, Manas Kulkarni - manask
`timescale 1ns / 1ps

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   // Generate and propagate signals for single bit
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits internally would generate a carry-out (independent of cin)
 * @param pout whether these 4 bits internally would propagate an incoming carry from cin
 * @param cout the carry outs for the low-order 3 bits
 */

module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);
   // Generate and propagate signals for 4-bit window

   // Compute carry out for each bit
   assign cout[0]= gin[0]|(pin[0] & cin);
   assign cout[1]= gin[1]|(pin[1] & gin[0])|(pin[1] & pin[0] & cin);
   assign cout[2]= gin[2]|(pin[2] & gin[1])|(pin[2] & pin[1] & gin[0])|(pin[2] & pin[1] & pin[0] & cin);

   // Compute generate and propagate signals for the entire 4-bit window
   assign gout =gin[3]|(pin[3] & gin[2])|(pin[3] & pin[2] & gin[1])|(pin[3] & pin[2] &pin[1] & gin[0]);
   assign pout =pin[3] & pin[2] & pin[1] &pin[0];
endmodule

/** Same as gp4 but for an 8-bit window instead */
module gp8(input wire [7:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [6:0] cout);

   // Generate and propagate signals for 8-bit window
   logic [6:0] cout_store;

   always_comb begin
      // Compute carry out for each bit
      assign cout_store[0] = gin[0]|(pin[0] & cin);
      assign cout_store[1] = gin[1]|(pin[1] & cout_store[0]);
      assign cout_store[2] = gin[2]|(pin[2] & cout_store[1]);
      assign cout_store[3] = gin[3]|(pin[3] & cout_store[2]);
      assign cout_store[4] = gin[4]|(pin[4] & cout_store[3]);
      assign cout_store[5] = gin[5]|(pin[5] & cout_store[4]);
      assign cout_store[6] = gin[6]|(pin[6] & cout_store[5]);
   end

   // Compute generate and propagate signals for the entire 8-bit window
   assign gout = gin[7] | (pin[7] & cout_store[6]);
   assign pout = (& pin);
   assign cout = cout_store;

endmodule

module cla
  (input wire [31:0]  a, b,
   input wire         cin,
   output wire [31:0] sum);

   // Carry Lookahead Adder
   
   // Generate and propagate signals for each bit
   wire [31:0] gin1 ;
   wire [31:0] pin1;

   // Storage for intermediate sum
   reg [31:0] sum_store;

   // Storage for carry out of each bit
   wire [30:0] cout;
   wire [4:0] gout;
   wire [4:0] pout;
   
   // Generate generate/propagate signals for each bit
   generate
      for(genvar i = 0; i < 32; i = i +1) begin : gp_1
         gp1 gp_1_( .a(a[i]), .b(b[i]), .g(gin1[i]), .p(pin1[i]));
      end : gp_1
   endgenerate 

   // Calculate generate/propagate signals for 8-bit windows
   gp8 gp8_1 (.gin(gin1[7:0]), .pin(pin1[7:0]), .cin(cin), .gout(gout[0]), .pout(pout[0]), .cout(cout[6:0]));

   for(genvar k = 1; k < 4; k = k + 1) begin : gp8_2
      gp8 gp8_2 (.gin(gin1[(k+1)*7:k*7]), .pin(pin1[(k+1)*7:k*7]), .cin(cout[(k*7)- 1]), .gout(gout[k]), .pout(pout[k]), .cout(cout[((k+1)*7)-1:k*7]));
   end : gp8_2

   // Calculate generate/propagate signals for the last 4 bits
   gp4 gp8_end (.gin(gin1[31:28]), .pin(pin1[31:28]), .cin(cout[27]), .gout(gout[4]), .pout(pout[4]), .cout(cout[30:28]));
 
   // Compute sum based on generate/propagate signals
   always_comb begin
      for(integer m = 0; m < 32; m = m + 1) begin : find_sum

         if(m == 0) begin : cin_1
            sum_store[m] = a[m] ^ b[m] ^ cin;
         end : cin_1

         else begin : cout_1
            sum_store[m] = a[m] ^ b[m] ^ cout[m-1];
         end : cout_1
         
      end : find_sum
   end   

   assign sum = sum_store;

endmodule
