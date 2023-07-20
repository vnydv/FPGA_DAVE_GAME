spriteSheet = """
TILE,
HEART,
KEY,
DAVE_NORMAL,
DAVE_RIGHT_LOOK,
DAVE_RIGHT_WALK,
DAVE_RIGHT_JUMP,
FIRE,
GATE,
TUNNEL,
DIGIT_0,
DIGIT_1,
DIGIT_2,
DIGIT_3,
DIGIT_4,
DIGIT_5,
DIGIT_6,
DIGIT_7,
DIGIT_8,
DIGIT_9,
LIVES,
COINS,
W,
O,
N,
L,
O,
S,
T"""

sprites = []

count = 0
for spn in spriteSheet.split(','):
    sprite_name = "SPRITE_" + spn.strip()
    sprite_address = hex(count*256)
    sprites.append(f"{sprite_name}={sprite_address}")
    count += 1
    print(sprites[-1])
