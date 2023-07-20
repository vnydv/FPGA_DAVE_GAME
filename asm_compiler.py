asmFile = "cu_test.asm"
binFile = "cu_test_rom.bin"
# asmFile = "pu_prog.asm"
# binFile = "pu_prog_rom.bin"

# create a dictionary of max memory, say 10*1024 len
memory = {i: "1111"+'1'*12 for i in range(1024)}
function_address = {}  # ".name" -> address
unresolved_references = [] # store address of memory

defined_address = {
    "AX":"0000",
    "BX":"0001",

    # store registers
    "AS":"0010",
    "BS":"0011",
    "CS":"0100",
    "DS":"0101",

    # subroutine paramter registers
    "AF":"0100",
    "BF":"0111",
    "CF":"1000",
    "DF":"1001",

    # pointers
    "IP":"1010",
    "SP":"1011",
    "BSP":"1100",

    "zero":"1101",
    "one":"1111"
    }
# pass through
# get address of all ".functions"
function_stack = []



fileData = []
with open(asmFile, 'r') as _file:
    # skip commennts and emtpy rows
    fileData = _file.readlines()


memory_pointer = 0

for l in fileData:
    _line = l.strip()
    if _line == "" or _line[0] == "#":
        continue

    if _line[0] == '.':        
        fnc = _line.rstrip(":")
        if fnc == ".end":
            function_stack.pop()
            continue

        print('got function:', fnc)
        function_stack.append(fnc)
        if fnc != ".define":
            function_address[fnc] = (bin(memory_pointer)[2:]).zfill(16)
        continue

        

    # save the defined constants
    if function_stack != [] and function_stack[-1] == ".define":
        ec = _line.count('=')
        if ec == 2:
            a,b,c = _line.split("=")
            b = int(b, 16)
            if 'x' in c:
                c = int(c, 16)
            else:
                c = int(c)
        
            defined_address[a] = (bin(b)[2:]).zfill(16)
            memory[b] = (bin(c)[2:]).zfill(16)
            memory_pointer = b+1

        else: # ec = 1
            a,b = _line.split("=")
            b = int(b, 16)
            defined_address[a] = b

        continue

    #--------------
    # note memory pointer only increases
    # decodes Instruction sets
    iset, *atbr = _line.split(" ")
    print('decoding:',iset, atbr)

    if iset == "sta_i" or iset == "stb_i":
        # A -> mem12[#]
        b = atbr[0]
        memval = "0000" if iset == "sta_i" else "0010"
        memval += "0" + (defined_address[b])[-11:]
    
    elif iset == "sta" or iset == "stb":
        # A -> mem[R1]
        b = atbr[0]
        memval = "0000" if iset == "sta" else "0010"
        memval += "1" + "0000" + (defined_address[b]) + "000"

    elif iset == "lda" or iset == "ldb":
        b = atbr[0]
        # ldx mem12[#]
        memval = "0001" if iset == "lda" else "0011"
        memval += "00" + (defined_address[b])[-10:]

    elif iset == "lda_ram" or iset == "ldb_ram" :
        b = atbr[0]        
        # load from rom immediate address - saved as 16 bit value
        memval = "0001" if iset == "lda_ram" else "0011"
        memval += "01"
        memval += "0000" if iset == "lda_ram" else "0001"
        memval += (defined_address[b])
        memval += "00";

    elif iset == "lda_rom" or iset == "ldb_rom" :
        b = atbr[0]
        # load from rom immediate address - saved as 16 bit value
        memval = "0001" if iset == "lda_rom" else "0011"
        memval += "11"
        memval += "0000" if iset == "lda_rom" else "0001"
        memval += (defined_address[b])
        memval += "00"

    elif iset == "mv":
        b,c = atbr[0], atbr[1]
        memval = "0100"
        memval += "01"
        memval += (defined_address[b])
        memval += (defined_address[c])
        memval += '00'

    elif iset == "jmp":
        # jmp R1
        # jmp 0x12f0
        b = atbr[0]
        if b in function_address:
            memval = "0111" + "00" + function_address[b][-10:]
        elif b in defined_address:
            # 10 bit
            memval = "0111" + "01" + defined_address[b] + "0"*6
        else:
            memval = ["0111",b]
            unresolved_references.append(memory_pointer)

    elif iset == "beq":
        # beq R1
        # beq 0x12f0
        b = atbr[0]
        if b in function_address:
            memval = "0101" + "00" + function_address[b][-12:]
        elif b in defined_address:
            # 10 bit
            memval = "0101" + "01" + defined_address[b] + "0"*6
        else:
            memval = ["0101",b]
            unresolved_references.append(memory_pointer)

    elif iset == "blt":
        # beq R1
        # beq 0x12f0
        b = atbr[0]
        if b in function_address:
            memval = "0110" + "00" + function_address[b][-12:]
        elif b in defined_address:
            # 10 bit
            memval = "0110" + "01" + defined_address[b] + "0"*6
        else:
            memval = ["0110",b]
            unresolved_references.append(memory_pointer)

    elif iset == "neg":
        b = atbr[0]
        memval = "1011"+"01"
        memval += (defined_address[b])
        memval += (defined_address[b])
        memval += '0'*(16-14)

    elif iset == "add":
        b,c = atbr[0], atbr[1]
        memval = "1001"+"01"
        memval += (defined_address[b])
        memval += (defined_address[c])
        memval += '0'*(16-14)

    elif iset == "nop":
        memval = '1'*16

    elif iset == "cmp":
        b,c = atbr[0], atbr[1]
        memval = "1010"+"01"
        memval += (defined_address[b])
        memval += (defined_address[c])
        memval += '0'*(16-14)

    elif iset == "and":
        b,c = atbr[0], atbr[1]
        memval = "1100"+"01"
        memval += (defined_address[b])
        memval += (defined_address[c])
        memval += '0'*(16-14)

    elif iset == "or":
        b,c = atbr[0], atbr[1]
        memval = "1101"+"01"
        memval += (defined_address[b])
        memval += (defined_address[c])
        memval += '0'*(16-14)
    
    elif iset == "xor":
        b,c = atbr[0], atbr[1]
        memval = "1110"+"01"
        memval += (defined_address[b])
        memval += (defined_address[c])
        memval += '0'*(16-14)

    memory[memory_pointer] = memval
    print(memval)
    memory_pointer += 1

    

# resolve undefined references
print("solving: unreferenced values")
for urf in unresolved_references:
    a,b = memory[urf]
    
    if b in function_address:
        memval = a + '00' + function_address[b][-10:]
        memory[urf] = memval
    else:
        print("ERROR: unreferenced", b)


# save to binfile
print('Saving to file')
with open(binFile, 'w') as _file:
    count = 0
    for mptr in memory:
        if mptr > memory_pointer: break
        _data = memory[mptr]
        print(_data[-16:-12],_data[-12:-10], _data[-10:-6], _data[-6:-2], _data[-2:], "|", _data)

        #fdata = f"mem[12'h{(hex(count)[2:]).zfill(3)}]=16'b{_data};"
        fdata = f"16'h{(hex(int(_data,2))[2:]).zfill(4)}"

        _file.write(fdata + ',\n')
        count+=1
