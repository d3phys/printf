import sys

ok   = "\u001b[32m✔\u001b[0m"
fail = "\u001b[31m✘\u001b[0m"

if len(sys.argv) < 2:
    exit(sys.argv[0] + ': Not enough arguments')

with open(sys.argv[1]) as file:
    lines = file.readlines()

test    = lines[0::2]
correct = lines[1::2]

if len(test) != len(correct):
    exit("Test count != answers")

    
passed = set(test) & set(correct)
for p in passed:
    print(ok, p[:-1])

failed = set(test) ^ set(correct)
for f in failed:
    print(fail, f[:-1])

print('-------------------------------')
print('PASS: {0} {2} FAIL: {1} {3}'.format(len(passed), len(failed) // 2, ok, fail))
print('-------------------------------')

