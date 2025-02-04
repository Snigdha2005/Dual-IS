module branch_predictor_2bit(
    input clk,                 // Clock signal
    input branch_taken,        // Actual branch outcome (1: taken, 0: not taken)
    output reg predict_taken   // Predicted branch outcome (1: taken, 0: not taken)
);

    typedef enum logic [1:0] {
        STRONGLY_NOT_TAKEN = 2'b00,
        WEAKLY_NOT_TAKEN   = 2'b01,
        WEAKLY_TAKEN       = 2'b10,
        STRONGLY_TAKEN     = 2'b11
    } state_t;

    state_t state, next_state;

    always @(*) begin
        case (state)
            STRONGLY_NOT_TAKEN: begin
                if (branch_taken)
                    next_state = WEAKLY_NOT_TAKEN;
                else
                    next_state = STRONGLY_NOT_TAKEN;
            end
            WEAKLY_NOT_TAKEN: begin
                if (branch_taken)
                    next_state = WEAKLY_TAKEN;
                else
                    next_state = STRONGLY_NOT_TAKEN;
            end
            WEAKLY_TAKEN: begin
                if (branch_taken)
                    next_state = STRONGLY_TAKEN;
                else
                    next_state = WEAKLY_NOT_TAKEN;
            end
            STRONGLY_TAKEN: begin
                if (branch_taken)
                    next_state = STRONGLY_TAKEN;
                else
                    next_state = WEAKLY_TAKEN;
            end
            default: next_state = STRONGLY_NOT_TAKEN; // Default case
        endcase
    end

    always @(posedge clk) begin
        state <= next_state;
    end

    always @(*) begin
        case (state)
            STRONGLY_NOT_TAKEN, WEAKLY_NOT_TAKEN: predict_taken = 0; // Predict not taken
            WEAKLY_TAKEN, STRONGLY_TAKEN: predict_taken = 1;         // Predict taken
            default: predict_taken = 0;
        endcase
    end

endmodule
