/*****************************************************************************************************
* Description:                 Direct Map Cache Controller for Demo
*
* Author:                      Dengxue Yan
*
* Email:                       Dengxue.Yan@wustl.edu
*
* Rev History:
 *       <Author>        <Date>        <Hardware>     <Version>        <Description>
*     Dengxue Yan   2017-02-18 17:00       --           1.00             Create
*****************************************************************************************************/
`timescale 1ns / 1ps

module CacheController(
    rst,
    clk,

    wr,
    rd,

    data_rd,
    data_wr,
    addr_req,
    addr_resp,

    rdy,
    busy,

    wr_mem,
    rd_mem,
    busy_mem,

    data_rd_mem,
    data_wr_mem,
    addr_mem,

    cache_miss_count,
    cache_hit_count
    );

    input  rst;// Reset
    input  clk;// System clk

    input  wr;
    input  rd;
    output [31:0] data_rd;
    reg    [31:0] data_rd;

    input  [31:0] data_wr;
    input  [31:0] addr_req;
    output [31:0] addr_resp;
    reg    [31:0] addr_resp;
    output rdy;
    reg    rdy;
    output busy;
    reg    busy;

    output  wr_mem;
    reg     wr_mem;
    output  rd_mem;
    reg     rd_mem;
    input   busy_mem;
    input  [31:0] data_rd_mem;
    output [31:0] data_wr_mem;
    reg    [31:0] data_wr_mem;
    output [31:0] addr_mem;
    reg    [31:0] addr_mem;

    output [31:0] cache_miss_count;
    reg    [31:0] cache_miss_count;
    output [31:0] cache_hit_count;
    reg    [31:0] cache_hit_count;

    reg [15:0]  cache_valid = 16'h0000;
    reg [15:0]  cache_dirty = 16'h0000;
    reg [23:0]  cache_tag [15:0];
    reg [127:0] cache_data[15:0];

    reg [2:0]   cache_state = 3'h0;
    reg [1:0]   cache_count = 2'h0;

    wire [23:0] addr_tag = addr_req[31:8];
    wire [3:0]  addr_index = addr_req[7:4];
    wire [3:0]  addr_offset = addr_req[3:0];

    reg  rd_temp = 1'b1;
    reg  [31:0] addr_temp = 0;
    reg  [31:0] data_wr_temp = 0;
    wire [23:0] addr_tag_temp = addr_temp[31:8];
    wire [3:0]  addr_index_temp = addr_temp[7:4];
    wire [3:0]  addr_offset_temp = addr_temp[3:0];

    // This part is used for debug to watch cache content in the waveform
    // Please keep this part when do simulation using VCS, so the content of the cache could be easily checked in dve
    wire [127:0] test00 = cache_data[0];
    wire [127:0] test01 = cache_data[1];
    wire [127:0] test02 = cache_data[2];
    wire [127:0] test03 = cache_data[3];
    wire [127:0] test04 = cache_data[4];
    wire [127:0] test05 = cache_data[5];
    wire [127:0] test06 = cache_data[6];
    wire [127:0] test07 = cache_data[7];
    wire [127:0] test08 = cache_data[8];
    wire [127:0] test09 = cache_data[9];
    wire [127:0] test10 = cache_data[10];
    wire [127:0] test11 = cache_data[11];
    wire [127:0] test12 = cache_data[12];
    wire [127:0] test13 = cache_data[13];
    wire [127:0] test14 = cache_data[14];
    wire [127:0] test15 = cache_data[15];

    wire [23:0] test100 = cache_tag[0];
    wire [23:0] test101 = cache_tag[1];
    wire [23:0] test102 = cache_tag[2];
    wire [23:0] test103 = cache_tag[3];
    wire [23:0] test104 = cache_tag[4];
    wire [23:0] test105 = cache_tag[5];
    wire [23:0] test106 = cache_tag[6];
    wire [23:0] test107 = cache_tag[7];
    wire [23:0] test108 = cache_tag[8];
    wire [23:0] test109 = cache_tag[9];
    wire [23:0] test110 = cache_tag[10];
    wire [23:0] test111 = cache_tag[11];
    wire [23:0] test112 = cache_tag[12];
    wire [23:0] test113 = cache_tag[13];
    wire [23:0] test114 = cache_tag[14];
    wire [23:0] test115 = cache_tag[15];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset
            rdy  <= 1'b0;
            busy <= 1'b0;
            data_rd <= 32'hZZZZZZZZ;

            cache_valid <= 16'h0000;
            cache_dirty <= 16'h0000;

            cache_state <= 3'h0;
            cache_count <= 2'h0;

            rd_mem <= 1'b0;
            wr_mem <= 1'b0;
            addr_mem <= 0;

            cache_miss_count   <= 0;
            cache_hit_count <= 0;

            rd_temp <= 1'b1;
            addr_temp <= 32'hZZZZZZZZ;
            addr_resp <= 32'hZZZZZZZZ;
            data_wr_mem <= 32'hZZZZZZZZ;
            data_wr_temp <= 32'hZZZZZZZZ;
            data_rd <= 32'hZZZZZZZZ;
        end
        else begin
            case (cache_state)
            3'h0:
            begin
                wr_mem <= 1'b0;
                rd_mem <= 1'b0;
                if ((rd) || (wr))
                begin
                    if ((cache_valid & (1 << addr_index)) && (cache_tag[addr_index] == addr_tag))// Cache hit
                    begin
                        addr_resp <= addr_req;
                        cache_hit_count <= cache_hit_count + 1'b1;
                        if (wr) begin
                            case (addr_offset[3:2])
                            2'h0: cache_data[addr_index][31:0]   <= data_wr;
                            2'h1: cache_data[addr_index][63:32]  <= data_wr;
                            2'h2: cache_data[addr_index][95:64]  <= data_wr;
                            2'h3: cache_data[addr_index][127:96] <= data_wr;
                            endcase
                            cache_dirty <= cache_dirty | (1 << addr_index);
                        end else begin
                            case (addr_offset[3:2])
                            2'h0: data_rd <=  cache_data[addr_index][31:0];
                            2'h1: data_rd <=  cache_data[addr_index][63:32];
                            2'h2: data_rd <=  cache_data[addr_index][95:64];
                            2'h3: data_rd <=  cache_data[addr_index][127:96];
                            endcase
                        end
                        rdy  <= 1'b1;
                        busy <= 1'b0;
                    end else begin
                        cache_miss_count <= cache_miss_count + 1'b1;
                        addr_temp <= addr_req;
                        data_wr_temp <= data_wr;
                        rd_temp <= rd;
                        rdy  <= 1'b0;
                        busy <= 1'b1;
                        cache_count <= 0;
                        if ((cache_valid & (1 << addr_index)) && (cache_dirty & (1 << addr_index))) begin
                            cache_state <= 3'h1;
                        end else begin
                            cache_state <= 3'h2;
                        end
                    end
                end else begin
                    rdy <= 1'b0;
                    busy <= 1'b0;
                end
            end
            3'h1:// evit handle
            begin
                if (!busy_mem) begin
                    if (0 == cache_count) begin
                        addr_mem <= {cache_tag[addr_index_temp], addr_temp[7:4], 4'h0};
                    end else begin
                        addr_mem <= addr_mem + 4;
                    end

                    wr_mem <= 1'b1;
                    rd_mem <= 1'b0;

                    case (cache_count)
                    2'h0: data_wr_mem <= cache_data[addr_index_temp][31:0];
                    2'h1: data_wr_mem <= cache_data[addr_index_temp][63:32];
                    2'h2: data_wr_mem <= cache_data[addr_index_temp][95:64];
                    2'h3: data_wr_mem <= cache_data[addr_index_temp][127:96];
                    endcase

                    if (cache_count < 3) begin
                        cache_count <= cache_count + 1'b1;
                    end else begin
                        cache_count <= 0;
                        cache_state <= 3'h2;
                    end
                end
            end
            3'h2:// cache miss handle
            begin
                if (!busy_mem) begin
                    wr_mem <= 1'b0;
                    rd_mem <= 1'b1;
                    addr_mem <= {addr_temp[31:4], 4'h0};
                    cache_state <= 3'h3;
                end
            end
            3'h3:
            begin
                if (!busy_mem) begin
                    case (cache_count)
                    2'h0:  cache_data[addr_index_temp][31:0]   <= data_rd_mem;
                    2'h1:  cache_data[addr_index_temp][63:32]  <= data_rd_mem;
                    2'h2:  cache_data[addr_index_temp][95:64]  <= data_rd_mem;
                    2'h3:  cache_data[addr_index_temp][127:96] <= data_rd_mem;
                    endcase

                    if (cache_count < 3) begin
                        cache_count <= cache_count + 1'b1;
                        addr_mem <= addr_mem + 4;
                    end else begin
                        cache_count <= 0;
                        cache_state <= 3'h4;
                        cache_tag[addr_index_temp] <= addr_tag_temp;
                        cache_valid <= cache_valid | (1 << addr_index_temp);
                        cache_dirty <= cache_dirty & (~(1 << addr_index_temp));
                        wr_mem <= 1'b0;
                        rd_mem <= 1'b0;
                    end
                end
            end
            3'h4:
            begin
                if (rd_temp) begin
                    case (addr_offset_temp[3:2])
                    2'h0: data_rd <=  cache_data[addr_index_temp][31:0];
                    2'h1: data_rd <=  cache_data[addr_index_temp][63:32];
                    2'h2: data_rd <=  cache_data[addr_index_temp][95:64];
                    2'h3: data_rd <=  cache_data[addr_index_temp][127:96];
                    endcase
                end else begin
                    case (addr_offset_temp[3:2])
                    2'h0: cache_data[addr_index_temp][31:0]   <= data_wr_temp;
                    2'h1: cache_data[addr_index_temp][63:32]  <= data_wr_temp;
                    2'h2: cache_data[addr_index_temp][95:64]  <= data_wr_temp;
                    2'h3: cache_data[addr_index_temp][127:96] <= data_wr_temp;
                    endcase
                    cache_dirty <= cache_dirty | (1 << addr_index_temp);
                end
                addr_resp <= addr_temp;
                rdy  <= 1'b1;
                busy <= 1'b0;
                cache_state <= 3'h0;
            end
            default:
                cache_state <= 3'h0;
            endcase
        end
    end

endmodule
