asmFile = "cu_test.asm"
binFile = "cu_test_rom.bin"

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
                c = int(b, 16)
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

    if iset == "jmp":
        b = atbr[0]
        if b in function_address:
            memval = "0111" + function_address[b][-12:]
        else:
            memval = ["0111",b]
            unresolved_references.append(memory_pointer)

        memory[memory_pointer] = memval

    elif iset == "lda_rom_i":
        b = atbr[0]

        if b in defined_address: # always is - the program is wrong
            # load from rom immediate address - saved as 16 bit value
            memval = "000111" + (defined_address[b])[-10:]

    elif iset == "ldb_rom_i":
        b = atbr[0]

        if b in defined_address: # always is - the program is wrong
            # load from rom immediate address - saved as 16 bit value
            memval = "001111" + (defined_address[b])[-10:]

    elif iset == "mv":
        b,c = atbr[0], atbr[1]
        memval = "0100"
        memval += (defined_address[b])
        memval += (defined_address[c])
        memval += '0'*(16-12)
        
    elif iset == "add":
        b,c = atbr[0], atbr[1]
        memval = "1001"
        memval += (defined_address[b])
        memval += (defined_address[c])
        memval += '0'*(16-12)

    memory[memory_pointer] = memval
    memory_pointer += 1

    

# resolve undefined references
print("solving: unreferenced values")
for urf in unresolved_references:
    a,b = memory[urf]
    
    if b in function_address:
        memval = a + function_address[b][-12:]
        memory[urf] = memval
    else:
        print("ERROR: unreferenced", b)


# save to binfile
print('Saving to file')
with open(binFile, 'w') as _file:
    for mptr in memory:
        if mptr > memory_pointer: break
        _data = memory[mptr]     
        print(_data) 
        _file.write(_data + '\n')
