`timescale 1ns / 1ps

module AXI4LiteMaster#
	(
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		parameter integer C_M_AXI_DATA_WIDTH	= 32
	)
    (
        input   wire                            m_axi_aclk,
        input   wire                            m_axi_aresetn,

        // READ - WRITE SELECTION AND ADDR-DATA INPUT
        input   wire                            read_ena,
        input   wire                            write_ena,

        input   wire [C_M_AXI_ADDR_WIDTH-1:0]   read_addr,
        output  wire [C_M_AXI_DATA_WIDTH-1:0]   read_data,
        output  wire                            read_done,

        input   wire [C_M_AXI_ADDR_WIDTH-1:0]   write_addr,
        input   wire [C_M_AXI_DATA_WIDTH-1:0]   write_data,
        output  wire                            write_done,

        // READ ADDR CHANNEL
        output  wire [C_M_AXI_ADDR_WIDTH-1:0]   M_AXI_ARADDR,
        output  wire                            M_AXI_ARVALID,
        input   wire                            M_AXI_ARREADY,

        // READ DATA CHANNEL
        input   wire [C_M_AXI_DATA_WIDTH-1:0]   M_AXI_RDATA,
        input   wire [1:0]                      M_AXI_RRESP,
        input   wire                            M_AXI_RVALID,
        output  wire                            M_AXI_RREADY,

        // WRITE ADDR CHANNEL
        output  wire [C_M_AXI_ADDR_WIDTH-1:0]   M_AXI_AWADDR,
        output  wire                            M_AXI_AWVALID,
        input   wire                            M_AXI_AWREADY,

        // WRITE DATA CHANNEL
        output  wire [C_M_AXI_DATA_WIDTH-1:0]   M_AXI_WDATA,
        output  wire [3:0]                      M_AXI_WSTRB,
        output  wire                            M_AXI_WVALID,
        input   wire                            M_AXI_WREADY,

        // WRITE RESPONSE CHANNEL
        input   wire [1:0]                      M_AXI_BRESP,
        input   wire                            M_AXI_BVALID,
        output  wire                            M_AXI_BREADY
    );

    localparam  W_ADDR_DATA =   4'b0000;
    localparam  W_DONE      =   4'b0001;

    localparam  R_ADDR      =   4'b0000;
    localparam  R_DATA      =   4'b0001;
    localparam  R_DONE      =   4'b0010;

    reg [3:0]   state_write;
    reg [3:0]   state_read;

    reg [C_M_AXI_DATA_WIDTH-1:0]    r_read_data;
    reg                             w_done;
    reg                             r_done;

    reg [C_M_AXI_ADDR_WIDTH-1:0]    axi_araddr;
    reg                             axi_arvalid;
    reg                             axi_rready;


    reg [C_M_AXI_ADDR_WIDTH-1:0]    axi_awaddr;
    reg                             axi_awvalid;
    reg [C_M_AXI_DATA_WIDTH-1:0]    axi_wdata;
    reg                             axi_wvalid;
    reg [3:0]                       axi_wstrb;
    reg                             axi_bready;

    assign M_AXI_ARADDR     = axi_araddr;
    assign M_AXI_ARVALID    = axi_arvalid;
    assign M_AXI_RREADY     = axi_rready;
    assign M_AXI_AWADDR     = write_addr;
    assign M_AXI_AWVALID    = axi_awvalid;
    assign M_AXI_WDATA      = write_data;
    assign M_AXI_WVALID     = axi_wvalid;
    assign M_AXI_WSTRB      = axi_wstrb;
    assign M_AXI_BREADY     = axi_bready;

    assign read_data        = r_read_data;
    assign write_done       = w_done;
    assign read_done        = r_done;


    // WRITE PROCESS
    always @(posedge m_axi_aclk or negedge m_axi_aresetn) begin
        if (!m_axi_aresetn) begin
            state_write <=  W_ADDR_DATA;
            axi_awaddr  <=  0;
            axi_awvalid <=  1'b0;
            axi_wdata   <=  0;
            axi_wvalid  <=  1'b0;
            axi_wstrb   <=  0;
            axi_bready  <=  1'b0;
            w_done      <=  1'b0;
        end
        else if (write_ena) begin
            axi_awaddr  <=  write_addr;
            axi_wdata   <=  write_data;
            case (state_write)
                W_ADDR_DATA : begin
                    axi_awvalid <=  1'b1;
                    axi_wvalid  <=  1'b1;
                    axi_wstrb   <=  4'b1111;
                    w_done      <=  1'b0;
                    if (M_AXI_AWREADY && M_AXI_WREADY) begin
                        axi_awvalid <=  1'b0;
                        axi_wvalid  <=  1'b0;
                        axi_bready  <=  1'b1;
                        axi_awaddr  <=  write_addr;
                        axi_wdata   <=  write_data;
                        state_write <=  W_DONE;
                    end
                    else begin
                        state_write <=  W_ADDR_DATA;
                    end
                end 

                W_DONE : begin
                    if (M_AXI_BRESP == 0 && M_AXI_BVALID) begin
                        state_write <=  W_ADDR_DATA;
                        axi_awaddr  <=  write_addr;
                        axi_wdata   <=  write_data;
                        axi_awvalid <=  1'b1;
                        axi_wvalid  <=  1'b1;
                        axi_bready  <=  1'b0;
                        w_done      <=  1'b1;
                    end
                    else begin
                        state_write <=  W_DONE;
                    end
                end 

                default: begin
                    state_write <=  W_ADDR_DATA;
                    axi_awaddr  <=  0;
                    axi_awvalid <=  1'b0;
                    axi_wdata   <=  0;
                    axi_wvalid  <=  1'b0;
                    axi_wstrb   <=  0;
                    axi_bready  <=  1'b0;
                end 
            endcase
        end
        else begin
            state_write <=  W_ADDR_DATA;
            axi_awaddr  <=  0;
            axi_awvalid <=  1'b0;
            axi_wdata   <=  0;
            axi_wvalid  <=  1'b0;
            axi_wstrb   <=  0;
            axi_bready  <=  1'b0;
            w_done      <=  1'b0;
        end
    end

    // READ PROCESS
    always @(posedge m_axi_aclk or negedge m_axi_aresetn) begin
        if (!m_axi_aresetn) begin
            state_read  <=  R_ADDR;
            axi_araddr  <=  0;
            axi_arvalid <=  1'b0;
            axi_rready  <=  1'b0;
            r_read_data <=  0;
            r_done      <=  1'b0;
        end
        else if (read_ena == 1'b1) begin
            case (state_read)
                R_ADDR : begin
                    axi_araddr  <=  read_addr;
                    axi_arvalid <=  1'b1;
                    axi_rready  <=  1'b1;
                    r_done      <=  1'b0;
                    if(M_AXI_ARREADY) begin
                        state_read  <=  R_DATA;
                        axi_arvalid <=  1'b0;
                    end
                    else begin
                        state_read  <=  R_ADDR;
                    end
                end 

                R_DATA : begin
                    if (M_AXI_RVALID) begin
                        state_read  <=  R_ADDR;
                        r_read_data <=  M_AXI_RDATA;
                        axi_araddr  <=  read_addr;
                        axi_arvalid <=  1'b1;
                        axi_rready  <=  1'b1;
                        r_done      <=  1'b1;
                    end
                    else begin
                        state_read  <=  R_DATA;
                    end
                end

                default: begin
                    state_read  <=  R_ADDR;
                    axi_araddr  <=  0;
                    axi_arvalid <=  1'b0;
                    axi_rready  <=  1'b0;
                    r_done      <=  1'b0;
                    r_read_data <=  0;
                end
            endcase
        end
        else begin
            state_read  <=  R_ADDR;
            axi_araddr  <=  0;
            axi_arvalid <=  1'b0;
            axi_rready  <=  1'b0;
            r_read_data <=  0;
            r_done      <=  1'b0;
        end
    end

endmodule
