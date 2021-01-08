cdef enum Subarray:
    LEFT,
    RIGHT


cdef int GRAIL_STATIC_EXT_BUFFER_LEN = 512


cdef class GrailSort:
    cdef list extBuffer
    cdef int extBufferLen

    cdef int currBlockLen
    cdef Subarray currBlockOrigin

    @staticmethod
    cdef void grailSwap(list array, int a, int b):
        cdef object temp = array[a]
        array[a] = array[b]
        array[b] = temp
    
    @staticmethod
    cdef void grailBlockSwap(list array, int a, int b, int blockLen):
        cdef int i
        for i in range(blockLen):
            GrailSort.grailSwap(array, a + i, b + i)

    @staticmethod
    cdef void grailRotate(list array, int start, int leftBlock, int rightBlock):
        while leftBlock > 0 and rightBlock > 0:
            if leftBlock <= rightBlock:
                GrailSort.grailBlockSwap(array, start, start + leftBlock, leftBlock)
                start += leftBlock
                rightBlock -= leftBlock
            else:
                GrailSort.grailBlockSwap(array, start + leftBlock - rightBlock, start + leftBlock, rightBlock)
                leftBlock -= rightBlock

    @staticmethod
    cdef void grailInsertSort(list array, int start, int length):
        cdef int item, left, right
        for item in range(1, length):
            left = start + item - 1
            right = start + item

            while left >= start and array[left] > array[right]:
                GrailSort.grailSwap(array, left, right)
                left -= 1
                right -= 1
    
    @staticmethod
    cdef int grailBinarySearchLeft(list array, int start, int length, object target):
        cdef int left = 0
        cdef int right = length

        cdef int middle
        while left < right:
            middle = left + ((right - left) // 2)

            if array[start + middle] < target:
                left = middle + 1
            else:
                right = middle
        return left

    @staticmethod
    cdef int grailBinarySearchRight(list array, int start, int length, object target):
        cdef int left = 0
        cdef int right = length

        cdef int middle
        while left < right:
            middle = left + ((right - left) // 2)

            if array[start + middle] > target:
                right = middle
            else:
                left = middle + 1
        return right

    @staticmethod
    cdef void grailLazyMerge(list array, int start, int leftLen, int rightLen):
        cdef int middle, mergeLen, end
        if leftLen < rightLen:
            middle = start + leftLen

            while leftLen != 0:
                mergeLen = GrailSort.grailBinarySearchLeft(array, middle, rightLen, array[start])

                if mergeLen != 0:
                    GrailSort.grailRotate(array, start, leftLen, mergeLen)
                    start += mergeLen
                    rightLen -= mergeLen
                
                middle += mergeLen

                if rightLen == 0:
                    break
                else:
                    while True:
                        start += 1
                        leftLen -= 1
                        if not (leftLen != 0 and array[start] <= array[middle]):
                            break
        else:
            end = start + leftLen + rightLen - 1

            while rightLen != 0:
                mergeLen = GrailSort.grailBinarySearchRight(array, start, leftLen, array[end])

                if mergeLen != leftLen:
                    GrailSort.grailRotate(array, start + mergeLen, leftLen - mergeLen, rightLen)
                    end -= leftLen - mergeLen
                    leftLen = mergeLen
                
                if leftLen == 0:
                    break
                else:
                    middle = start + leftLen
                    while True:
                        rightLen -= 1
                        end -= 1
                        if not (rightLen != 0 and array[middle - 1] <= array[end]):
                            break

    @staticmethod
    cdef void grailLazyStableSort(list array, int start, int length):
        cdef int index, left, right
        for index in range(1, length, 2):
            left = start + index - 1
            right = start + index

            if array[left] > array[right]:
                GrailSort.grailSwap(array, left, right)
        cdef int mergeLen, fullMerge, mergeIndex, mergeEnd, leftOver
        mergeLen = 2
        while mergeLen < length:
            fullMerge = 2 * mergeLen

            mergeEnd = length - fullMerge   

            for mergeIndex from 0 <= mergeIndex <= mergeEnd by fullMerge:
                GrailSort.grailLazyMerge(array, start + mergeIndex, mergeLen, mergeLen)

            leftOver = length - mergeIndex
            if leftOver > mergeLen:
                GrailSort.grailLazyMerge(array, start + mergeIndex, mergeLen, leftOver - mergeLen)
            mergeLen *= 2
    
    @staticmethod
    cdef int grailCollectKeys(list array, int start, int length, int idealKeys):
        cdef int keysFound = 1
        cdef int firstKey = 0
        cdef int currKey = 1

        cdef int insertPos
        while currKey < length and keysFound < idealKeys:
            insertPos = GrailSort.grailBinarySearchLeft(array, start + firstKey, keysFound, array[start + currKey])

            if insertPos == keysFound or array[start + currKey] != array[start + firstKey + insertPos]:
                GrailSort.grailRotate(array, start + firstKey, keysFound, currKey - (firstKey + keysFound))

                firstKey = currKey - keysFound

                GrailSort.grailRotate(array, start + firstKey + insertPos, keysFound - insertPos, 1)

                keysFound += 1
            currKey += 1
        
        GrailSort.grailRotate(array, start, firstKey, keysFound)
        return keysFound

    cpdef void grailCommonSort(self, list array, int start, int length, list extBuffer, int extBufferLen):
        if length < 16:
            GrailSort.grailInsertSort(array, start, length)
            return
        
        cdef int blockLen = 1

        while blockLen * blockLen < length:
            blockLen *= 2

        cdef int keyLen = ((length - 1) // blockLen) + 1

        cdef int idealKeys = keyLen + blockLen

        cdef int keysFound = GrailSort.grailCollectKeys(array, start, length, idealKeys)

        cdef bint idealBuffer
        if keysFound < idealKeys:
            if keysFound < 4:
                GrailSort.grailLazyStableSort(array, start, length)
                return
            else:
                keyLen = blockLen
                blockLen = 0
                idealBuffer = False

                while keyLen > keysFound:
                    keyLen //= 2
        else:
            idealBuffer = True
