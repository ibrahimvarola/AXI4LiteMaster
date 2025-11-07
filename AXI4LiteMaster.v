`timescale 1ns / 1ps

module AXI4LiteMaster #
    (
        parameter integer   AXI_ADDR_WIDTH  = 32,
        parameter integer   AXI_DATA_WIDTH  = 32
    )
    (
        input   wire                        m_axi_aclk,
        input   wire                        m_axi_aresetn,

        input   wire                        write_ena,
        output  reg                         write_done,
        input   wire [AXI_ADDR_WIDTH-1:0]   write_addr,
        input   wire [AXI_DATA_WIDTH-1:0]   write_data,

        input   wire                        read_ena,
        output  reg                         read_done,
        input   wire [AXI_ADDR_WIDTH-1:0]   read_addr,
        output  wire [AXI_DATA_WIDTH-1:0]   read_data,

        // READ ADDR CHANNEL
        output  wire [AXI_ADDR_WIDTH-1:0]   M_AXI_ARADDR,
        output  reg                         M_AXI_ARVALID,
        input   wire                        M_AXI_ARREADY,

        // READ DATA CHANNEL
        input   wire [AXI_DATA_WIDTH-1:0]   M_AXI_RDATA,
        input   wire [1:0]                  M_AXI_RRESP,
        input   wire                        M_AXI_RVALID,
        output  reg                         M_AXI_RREADY,

        // WRITE ADDR CHANNEL
        output  wire [AXI_ADDR_WIDTH-1:0]   M_AXI_AWADDR,
        output  reg                         M_AXI_AWVALID,
        input   wire                        M_AXI_AWREADY,

        // WRITE DATA CHANNEL
        output  wire [AXI_DATA_WIDTH-1:0]   M_AXI_WDATA,
        output  reg  [3:0]                  M_AXI_WSTRB,
        output  reg                         M_AXI_WVALID,
        input   wire                        M_AXI_WREADY,

        // WRITE RESPONSE CHANNEL
        input   wire [1:0]                  M_AXI_BRESP,
        input   wire                        M_AXI_BVALID,
        output  reg                         M_AXI_BREADY
    );

    assign  M_AXI_ARADDR    = read_addr;
    assign  M_AXI_AWADDR    = write_addr;
    assign  M_AXI_WDATA     = write_data;
    assign  read_data       = M_AXI_RDATA;

    always @(posedge m_axi_aclk or negedge m_axi_aresetn) begin
        if (!m_axi_aresetn) begin
            M_AXI_AWVALID   <=  1'b0;
        end
        else begin
            if (write_ena) begin
                M_AXI_AWVALID   <=  1'b1;   
            end
            else if ((M_AXI_AWREADY && M_AXI_AWVALID)) begin
                M_AXI_AWVALID   <=  1'b0;
            end
        end
    end

    always @(posedge m_axi_aclk or negedge m_axi_aresetn) begin
        if (!m_axi_aresetn) begin
            M_AXI_WVALID    <=  1'b0;
            M_AXI_WSTRB     <=  0;
        end
        else begin
            if (write_ena) begin
                M_AXI_WVALID    <=  1'b1;
                M_AXI_WSTRB     <=  4'b1111;
            end
            else if ((M_AXI_WREADY && M_AXI_WVALID)) begin
                M_AXI_AWVALID   <=  1'b0;
                M_AXI_WSTRB     <=  0;
            end
        end
    end

    always @(posedge m_axi_aclk or negedge m_axi_aresetn) begin
        if (!m_axi_aresetn) begin
            M_AXI_BREADY    <=  1'b0;
            write_done      <=  1'b0;
        end
        else begin
            M_AXI_BREADY    <=  1'b1;
            write_done      <=  1'b0;

            if (M_AXI_BREADY && M_AXI_BVALID && M_AXI_BRESP == 0) begin
                write_done  <=  1'b1;
            end
        end
    end

    always @(posedge m_axi_aclk or negedge m_axi_aresetn) begin
        if (!m_axi_aresetn) begin
            M_AXI_ARVALID   <=  1'b0;
        end
        else begin
            if (read_ena) begin
                M_AXI_ARVALID   <=  1'b1;
            end
            else if ((M_AXI_ARREADY && M_AXI_ARVALID)) begin
                M_AXI_ARVALID   <=  1'b0;
            end
        end
    end

    always @(posedge m_axi_aclk or negedge m_axi_aresetn) begin
        if (!m_axi_aresetn) begin
            M_AXI_RREADY    <=  1'b0;
            read_done       <=  1'b0;
        end
        else begin
            M_AXI_RREADY    <=  1'b1;
            read_done       <=  1'b0;
            if (M_AXI_RRESP == 0) begin
                read_done       <=  1'b1;
            end
        end
    end

endmodule
