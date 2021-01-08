from grailsort import GrailSort
import random

LENGTH = 4096


l = [random.randrange(LENGTH) for _ in range(LENGTH)]
gs = GrailSort()
gs.grailCommonSort(l, 0, LENGTH, None, 0)
print(all(l[i - 1] <= l[i] for i in range(1, LENGTH)))
