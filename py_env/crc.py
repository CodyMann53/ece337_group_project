import math
x = 0b101
y = 0b11111

z = (y << x.bit_length()) | x

#the message to be sent should be an integer and not a string
def calc_crc_token(message):
    #define the generating function (poly x^16 + x^15 + x^2 + 1)
    poly = 0b11000000000000101

    #6 bit operation register, initialized to all ones
    reg = 0b1111111111111111

    #defining the mask to check if msb in shift register bit
    mask = 0b1000000000000000

    #for every bit in message
    for x in bin(message)[2:]:

        #if the msb is a one
        if ( ( (mask & reg) != 0) & (int(x) == 1) ):

            #update the reg and shift in a one
            reg = ( (reg << 1) | 1 ) ^ poly 

        elif( ( (mask & reg) != 0) & (int(x) == 0) ): #msb is a one but shifting in a zero

            #update reg and shift in a zero
            reg = ( (reg << 1) | 0 ) ^ poly 

        elif ( ((mask & reg) == 0) & (int(x) == 1)): #msb is a zero and shifting in 1

            #update reg
            reg = ( (reg << 1) | 1 ) ^ 0b0

        else: #msb is a zero and shifting in 0

            #update reg
            reg = ( (reg << 1) | 0 ) ^ 0b0

        #shift off the msb to keep it 16its
        reg = 0b1111111111111111 & reg

    #return the crc
    return reg 

#builes a message up based on a list of bytes to send
def build_message(byte_list):

    #Initialize message to zero
    message = 0;

    #loop through all of the byte_list
    for byte in byte_list:

        #add the byte to the message
        message = (byte << message.bit_length()) | message

    return message



byte_list = {0, 1, 2, 3, 4, 5}
message = build_message(byte_list)
crc = calc_crc_token(message << 16)
print(crc)
message = (message << 16) | crc
print( calc_crc_token(message) )
