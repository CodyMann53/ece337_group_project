import math
x = 0b101
y = 0b11111

z = (y << x.bit_length()) | x

#the message to be sent should be an integer and not a string
def calc_crc_token(message):
    #define the generating function (poly x^5 + x^2 + 1)
    poly = 0b100101

    #6 bit operation register, initialized to all ones
    reg = 0b111111

    #defining the mask to check if msb in shift register bit
    mask = 0b100000

    #for every bit in message
    for x in bin(message)[2:]:

        #if the msb is a one
        if ( ( (mask & reg) != 0) & (int(x) == 1) ):

            #update the reg and shift in a one
            reg = ( (reg ^ poly) << 1) | 1

        elif( ( (mask & reg) != 0) & (int(x) == 0) ): #msb is a one but shifting in a zero

            #update reg and shift in a zero
            reg = ( (reg ^ poly) << 1) | 0

        elif ( ((mask & reg) == 0) & (int(x) == 1)): #msb is a zero and shifting in 1

            #update reg
            reg = (reg << 1 ) | 1

        else: #msb is a zero and shifting in 0

            #update reg
            reg = (reg << 1 ) | 0

        #shift off the msb to keep it 6 bits
        reg = 0b111111 & reg

    #return the crc
    return reg
