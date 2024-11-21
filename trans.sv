class trans extends uvm_sequence_item;
    // Random control signals
    rand logic wr_en;
    rand logic rd_en;
    rand logic [31:0] data_in;

    // Status signals
    logic fifo_full;
    logic fifo_empty;
    logic fifo_almost_full;
    logic fifo_almost_empty;
    logic [31:0] data_out;

    // UVM Macro for Factory Registration
    `uvm_object_utils_begin(trans)
        `uvm_field_int(wr_en,   UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(rd_en,   UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(data_in, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constraints
    constraint write_read_mutex {
        // Mutual exclusion between write and read
        wr_en != rd_en;
    }

    // Optional additional constraints for more realistic scenarios
    constraint reasonable_activity {
        // Soft constraint to balance write and read activities
        soft wr_en dist {0 := 50, 1 := 50};
        soft rd_en dist {0 := 50, 1 := 50};
    }

    // Constructor
    function new(string name = "trans");
        super.new(name);
    endfunction

    // Optional utility methods
    function string convert2string();
        return $sformatf(
            "wr_en:%0b, rd_en:%0b, data_in:0x%0h, " + 
            "fifo_full:%0b, fifo_empty:%0b", 
            wr_en, rd_en, data_in, fifo_full, fifo_empty
        );
    endfunction

    // Optional method for additional randomization control
    function void post_randomize();
        // You can add any post-randomization logic here
        // For example, additional checks or modifications
    endfunction
endclass