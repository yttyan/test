
always @ *
begin
    next_state_r   = state_q;
    target_state_r = target_state_q;

    case (state_q)
    //-----------------------------------------
    // STATE_INIT
    //-----------------------------------------
    STATE_INIT :
    begin
        if (refresh_q)
            next_state_r = STATE_IDLE;
    end
    //-----------------------------------------
    // STATE_IDLE
    //-----------------------------------------
    STATE_IDLE :
    begin
        // Pending refresh
        // Note: tRAS (open row time) cannot be exceeded due to periodic
        //        auto refreshes.
        if (refresh_q)
        begin
            // Close open rows, then refresh
            if (|row_open_q)
                next_state_r = STATE_PRECHARGE;
            else
                next_state_r = STATE_REFRESH;

            target_state_r = STATE_REFRESH;
        end
        // Access request
        else if (stb_i && cyc_i)
        begin
            // Open row hit
            if (row_open_q[addr_bank_w] && addr_row_w == active_row_q[addr_bank_w])
            begin
                if (we_i)
                    next_state_r = STATE_WRITE0;
                else
                    next_state_r = STATE_READ;
            end
            // Row miss, close row, open new row
            else if (row_open_q[addr_bank_w])
            begin
                next_state_r   = STATE_PRECHARGE;

                if (we_i)
                    target_state_r = STATE_WRITE0;
                else
                    target_state_r = STATE_READ;
            end
            // No open row, open row
            else
            begin
                next_state_r   = STATE_ACTIVATE;

                if (we_i)
                    target_state_r = STATE_WRITE0;
                else
                    target_state_r = STATE_READ;
            end
        end
    end
    //-----------------------------------------
    // STATE_ACTIVATE
    //-----------------------------------------
    STATE_ACTIVATE :
    begin
        // Proceed to read or write state
        next_state_r = target_state_r;
    end
    //-----------------------------------------
    // STATE_READ
    //-----------------------------------------
    STATE_READ :
    begin
        next_state_r = STATE_READ_WAIT;
    end
    //-----------------------------------------
    // STATE_READ_WAIT
    //-----------------------------------------
    STATE_READ_WAIT :
    begin
        next_state_r = STATE_IDLE;

        // Another pending read request (with no refresh pending)
        if (!refresh_q && stb_i && cyc_i && !we_i)
        begin
            // Open row hit
            if (row_open_q[addr_bank_w] && addr_row_w == active_row_q[addr_bank_w])
                next_state_r = STATE_READ;
        end
    end
    //-----------------------------------------
    // STATE_WRITE0
    //-----------------------------------------
    STATE_WRITE0 :
    begin
        next_state_r = STATE_WRITE1;
    end
    //-----------------------------------------
    // STATE_WRITE1
    //-----------------------------------------
    STATE_WRITE1 :
    begin
        next_state_r = STATE_IDLE;

        // Another pending write request (with no refresh pending)
        if (!refresh_q && stb_i && cyc_i && we_i)
        begin
            // Open row hit
            if (row_open_q[addr_bank_w] && addr_row_w == active_row_q[addr_bank_w])
                next_state_r = STATE_WRITE0;
        end
    end
    //-----------------------------------------
    // STATE_PRECHARGE
    //-----------------------------------------
    STATE_PRECHARGE :
    begin
        // Closing row to perform refresh
        if (target_state_r == STATE_REFRESH)
            next_state_r = STATE_REFRESH;
        // Must be closing row to open another
        else
            next_state_r = STATE_ACTIVATE;
    end
    //-----------------------------------------
    // STATE_REFRESH
    //-----------------------------------------
    STATE_REFRESH :
    begin
        next_state_r = STATE_IDLE;
    end
    //-----------------------------------------
    // STATE_DELAY
    //-----------------------------------------
    STATE_DELAY :
    begin
        next_state_r = delay_state_q;
    end
    default:
        ;
   endcase
end
