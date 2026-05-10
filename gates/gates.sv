module gates ( 
    input a, b,
    output c
);

    and (c, a, b);

    initial begin 
        $display("Hello World"); 
        //$finish; 

        

        $finish; 
    end

endmodule;
