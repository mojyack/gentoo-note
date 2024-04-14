partitions = [
    [1, "D69E90A5-4CAB-0071-F6DF-AB977F141A7F"],  # aop
    [2, "A053AA7F-40B8-4B1C-BA08-2F68AC71A4F4"],  # tz
    [3, "E1A6A689-0C8D-4CC6-B4E8-55A4320FBD8A"],  # hyp
    [8, "BD6928A1-4CE0-A038-4F3A-1495E3EDDFFB"],  # abl
    [10, "A11D2A7C-D82A-4C2F-8A01-1805240E6626"],  # keymaster
    [11, "20117F86-E985-4357-B9EE-374BC1D8487D"],  # boot
    [12, "73471795-AB54-43F9-A847-4F72EA5CBEF5"],  # cmnlib
    [13, "8EA64893-1267-4A1B-947C-7C362ACAAD2C"],  # cmnlib64
    [14, "F65D4B16-343D-4E25-AAFC-BE99B6556A6D"],  # devcfg
    [15, "21D1219F-2ED1-4AB4-930A-41A16AE75F7F"],  # qfwup
    [17, "4B7A15D6-322C-42AC-8110-88B7DA0C5D77"],  # vbmeta
]

inactive_code = "77036CD4-03D5-42BB-8ED1-37E5A88BAA34"
b_offset = 28

for p in partitions:
    num = p[0]
    code = p[1]
    num_b = num + b_offset
    print(f"-t {num}:{code}")
    print(f"-t {num_b}:{inactive_code}")
    print(f"-A {num}:clear:55 -A {num}:set:54 -A {num}:set:53 -A {num}:set:52 -A {num}:set:51 -A {num}:set:50 -A {num}:set:49 -A {num}:set:48") # 0x7F
    print(f"-A {num_b}:set:55 -A {num_b}:clear:50")
