from tqdm import tqdm
import random as rnd
total_error = 0

def multiply_bin(a, b, ignored=0, bits=16):
    a_bin = f"{a:0{bits}b}"
    result = 0
    for bit in range(bits):
        if a_bin[-bit - 1] == '1':
            b_truncated = int(f"{b:0{bits}b}"[:bits - max(ignored - bit, 0)] + '0' * max(ignored - bit, 0), 2)
            result += b_truncated * (2 ** bit)
    return f"{result:032b}"

# monte carlo simulation
rnd.seed("lazy")
for laziness in tqdm(range(16)):
    for _ in (range(2**16)):
        a = rnd.randint(0, 2**16 - 1)
        b = rnd.randint(0, 2**16 - 1)
        correct = int(bin(a * b)[2:], 2) // (2**16)
        result = int(multiply_bin(a, b, ignored=laziness), 2) // (2**16)
        total_error += abs(correct - result)
    # print(f"bits dropped: {laziness} average error per calculation: {total_error / (2**16)}")

# error_count = 0
# total_error = 0
# for a in tqdm(range(2**16)):
#     for b in range(2**16):
#         correct = int(bin(a * b)[2:], 2) // (2**16)
#         result = int(multiply_bin(a, b, ignored=16), 2) // (2**16)
#         if correct != result:
#             error_count += 1
#             total_error += abs(correct - result)
# print(f"""avg error: {total_error / (2**32)}, 
#       error count: {error_count}, 
#       avg error per error: {total_error / error_count}""")