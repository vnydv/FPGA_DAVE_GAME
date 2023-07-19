// testing PPU unit

module motherboard(clk, reset, hsync, vsync, switches, rgb);

    input clk, reset;
    output hsync, vsync;
    input wire[4:0] switches;
    output wire [12:0] rgb;

    // current ray drawble screen
    wire [15:0] hpos;
    wire [15:0] vpos;
    wire display_on;

    // busses
    wire [15:0] pu_addr_bus;
    wire [15:0] pu_data_bus;

    // ppu RAM bus
    wire [15:0] pu_ram_read;
    wire [15:0] pu_ram_write;
    wire [15:0] pu_ram_writeenable;

    RAM_DP_pu pu_ram(
        .clk(clk),
        .dout(pu_ram_read),
        .din(pu_ram_write),
        .addr(pu_addr_bus),
        .we(pu_ram_writeenable)
    );
    // specific location to extract rgb values directly
    assign rgb = pu_ram.RAM[`RGB_ADDRESS]

    // ppu ROM bus    
    wire [15:0] pu_rom_data;

    ROM pu_rom(
        .addr(pu_addr_bus);
        .data(pu_rom_read);
    )

    // if PPU busy -> reading from pu_ROM else from pu_ROM
    always @(*)
        pu_data_bus = ppu_busy ? pu_rom_read : pu_ram_read;

    CPU16 ppu(
        .clk(clk),
        .reset(reset),
        .busy(ppu_busy),
        .address(pu_addr_bus),
        .data_in(pu_data_bus),
        .data_out(pu_ram_write),
        .write(pu_ram_writeenable)
    );





endmodule