/*****************************************************************************************************
 * Description:                 Test bench for Cache ontroller
 *                              -- This test bench mainly used for test the miss rate of cache
 *
 * Author:                      Dengxue Yan
 *
 * Email:                       Dengxue.Yan@wustl.edu
 *
 * Rev History:
 *       <Author>        <Date>        <Hardware>     <Version>
 *     Dengxue Yan   2017-02-18 17:00       --           1.00             Create
 *****************************************************************************************************/
`timescale 1ns / 1ps

module CacheController_tb1();
    reg  clk;
    reg  rst;

    reg wr;
    reg rd;

    wire [31:0] data_rd;
    reg [31:0] data_wr;

    reg [31:0] addr_req;
    wire [31:0] addr_resp;

    wire rdy;
    wire busy;

    wire wr_mem;
    wire rd_mem;

    reg  [31:0] data_rd_mem;
    wire [31:0] data_wr_mem;

    wire [31:0] addr_mem;

    wire [31:0] cache_miss_count;
    wire [31:0] cache_hit_count;

    CacheController DUT(
    .rst(rst),
    .clk(clk),

    .wr(wr),
    .rd(rd),

    .data_rd(data_rd),
    .data_wr(data_wr),
    .addr_req(addr_req),
    .addr_resp(addr_resp),

    .rdy(rdy),
    .busy(busy),

    .wr_mem(wr_mem),
    .rd_mem(rd_mem),
    .busy_mem(1'b0),

    .data_rd_mem(data_rd_mem),
    .data_wr_mem(data_wr_mem),
    .addr_mem(addr_mem),

    .cache_miss_count(cache_miss_count),
    .cache_hit_count(cache_hit_count)
    );

    reg [31:0] ram[1024 * 1024 * 32 - 1: 0];
    reg [31:0] counter;

    // This part is used for debug to watch ram content in the waveform
    wire [31:0] test000 = ram[0];
    wire [31:0] test001 = ram[1];
    wire [31:0] test002 = ram[2];
    wire [31:0] test003 = ram[3];
    wire [31:0] test004 = ram[4];
    wire [31:0] test005 = ram[5];
    wire [31:0] test006 = ram[6];
    wire [31:0] test007 = ram[7];
    wire [31:0] test008 = ram[16];
    wire [31:0] test009 = ram[17];
    wire [31:0] test010 = ram[18];
    wire [31:0] test011 = ram[19];
    wire [31:0] test012 = ram[20];
    wire [31:0] test013 = ram[21];
    wire [31:0] test014 = ram[22];
    wire [31:0] test015 = ram[23];

    // Initialize memory content from "ram.bin"
    integer fd, i;
    reg [31:0] data;

    initial
    begin
        $dumpfile("CacheController1.vcd");
        $dumpvars(0, CacheController_tb1);

        fd = $fopen("ram.bin","rb");
        for (i = 0; (i < (1024 * 1024 * 1 / 4)) && ($fread(data, fd) != -1); i = i + 1)
            ram[i] = {data[7:0], data[15:8], data[23:16], data[31:24]};

        rst = 1;
        clk = 0;

        #50
        rst = 0;

        #10000000
        $fclose(fd);
        $finish;
    end

    reg cycle_end;
    reg [31:0] cycle_count;
    always @ (posedge clk)
    begin
        if (rst) begin
            counter <= 0;
            cycle_count <= 0;
        end
        else begin
            if (cycle_count < 16) begin
                if (!busy) begin
                    if (!cycle_end) begin
                        counter <= counter +1'b1;
                    end else begin
                        counter <= 0;
                        cycle_count <= cycle_count + 1'b1;
                    end
                end
            end else begin
                $fclose(fd);
                $finish;
            end
        end
    end

    `define READ_CYCLE 8
    wire [29:0] counter_for_wr = counter - `READ_CYCLE - 1 + 9'h100;
    always @ (counter or rst or busy)
    begin
        if (rst) begin
            wr = 1'b0;
            rd = 1'b0;
            addr_req = 0;
            data_wr = 0;
            cycle_end = 1'b0;
        end
        else begin
            if (!busy)
            begin
                if (counter < `READ_CYCLE) begin
                    cycle_end = 1'b0;
                    wr = 1'b1;
                    rd = 1'b0;
                    addr_req = {counter[29:0], 2'b00};
                    data_wr = counter;
                end else if (counter == `READ_CYCLE)begin
                    wr = 1'b0;
                    rd = 1'b0;
                    addr_req = 9'h100;
                end else if (counter < (`READ_CYCLE * 2 + 1)) begin
                    wr = 1'b0;
                    rd = 1'b1;
                    addr_req = {counter_for_wr[29:0], 2'b00};
                end else begin
                    wr = 1'b0;
                    rd = 1'b0;
                    cycle_end = 1'b1;
                end
            end
        end
    end

    always @ (negedge clk or posedge rst)
    begin
        if (rst) begin
        end else begin
            if (wr_mem) begin
               ram[addr_mem[31:2]] <= data_wr_mem;
            end else if (rd_mem) begin
               data_rd_mem   <= ram[addr_mem[31:2]];
            end
        end
    end

    always
        #10 clk = !clk;

endmodule
