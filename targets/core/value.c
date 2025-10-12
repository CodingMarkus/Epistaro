#include "fletcher32.h"

#include <stdalign.h>
#include <stdatomic.h>

#include "begin_impl.h"
begin_impl
// ============================================================================

#if TESTING || DEBUGGING
	#define ENABLE_HEAVY_CHECKS 1
#endif
#if DEVELOPING
	#define ENABLE_LIGHTWEIGHT_CHECKS 1
#endif
#if ENABLE_LIGHTWEIGHT_CHECKS || ENABLE_HEAVY_CHECKS
	#define CHECKS_ARE_ENABLED 1
#endif

struct Value {
	const struct ValueTypeDescriptor * typeDesc;
	union {
		uint_fast32_t refCount;
		atomic_uint_fast32_t atomicRefCount;
	};

	uint_fast16_t reserved:13;
	uint_fast16_t threadSafeFlag:1;
	uint_fast16_t immutableFlag:1;
	uint_fast16_t frozenFlag:1;

	uint_fast16_t size;

#if CHECKS_ARE_ENABLED
	uint32_t checksum;
#endif
};

// ----------------------------------------------------------------------------

#if CHECKS_ARE_ENABLED

static inline
uint32_t calcChecksum( struct Value * value )
{
#define f32feed(state, value) ({ \
    def _tmp = (value); \
    def _size = sizeof(_tmp); \
    Fletcher32Update((state), &_tmp, _size); \
})

    struct Fletcher32State st = { 0 };
    st = f32feed(st, value->size);
    st = f32feed(st, (const void *)value->typeDesc);
    st = f32feed(st, (const void *)value->typeDesc->name);
#if ENABLE_HEAVY_CHECKS
	st = f32feed(st, (const void *)value->typeDesc->copyFunc);
	st = f32feed(st, (const void *)value->typeDesc->freezeFunc);
	st = f32feed(st, (const void *)value->typeDesc->destroyFunc);
	st = f32feed(st, (const void *)value->typeDesc->createDescFunc);
#endif

#undef f32feed
    return Fletcher32Finalize(st);
}


static inline
void assertIsValue( void * ptr )
{
	def value = *(struct Value **)ptr;
	assert(
		calcChecksum(value) == value->checksum
	);
	if (likely_true(!value->threadSafeFlag)) {
		assert(value->refCount > 0);
	} else {
		def count = atomic_load(&value->atomicRefCount);
		assert(count > 0);
	}
}

#else
	#define assertIsValue(...)
#endif


static inline
void incRefCount( struct Value * value )
{
	if (likely_true(!value->threadSafeFlag)) {
		assert(value->refCount > 0);
		assert(value->refCount < UINT32_MAX);
		value->refCount++;
		return;
	}
	def oldCount = atomic_fetch_add(&value->atomicRefCount, 1);
	assert(oldCount > 0);
	assert(oldCount < UINT32_MAX);
}


static inline
bool decRefCount( struct Value * value )
{
	if (likely_true(!value->threadSafeFlag)) {
		assert(value->refCount > 0);
		return (--value->refCount != 0);
	}
	uint_fast32_t oldCount = atomic_fetch_sub(&value->atomicRefCount, 1);
	assert(oldCount > 0);
	return (oldCount != 1);
}

// ----------------------------------------------------------------------------

void *_nil retain_Value( void *_nil maybePtr )
{
	if_def (ptr, maybePtr) {
		assertIsValue(ptr);
		def value = *(struct Value **)ptr;
		incRefCount(value);
	}
	return maybePtr;
}


void discard_Value( void *_nil maybePtr )
{
	if_def (ptr, maybePtr) { } else { return; }
	assertIsValue(ptr);
	def value = *(struct Value **)ptr;

	if (likely_false(!decRefCount(value))) {
		if_def (destroyFunc, value->typeDesc->destroyFunc) {
			destroyFunc(ptr);
		}
		free(ptr);
	}
}


void *_nil copy_Value( void *_nil maybePtr, enum CopyStyle_Value style )
{
	if_def (ptr, maybePtr) { } else { return nil; }
	assertIsValue(ptr);
	def value = *(struct Value **)ptr;

	if (value->immutableFlag) {
		incRefCount(value);
		if (likely_false(style == ThreadSafe_CopyStyle_Value)) {
			value->threadSafeFlag = true;
			def copy = value->typeDesc->copyFunc(ptr, style);
			assert(copy == ptr);
			return copy;
		}
		return ptr;
	}

	assert(!value->threadSafeFlag);
	return value->typeDesc->copyFunc(ptr, style);
}


bool isEqual_Value( void *_nil maybePtr1, void *_nil maybePtr2 )
{
	if_def (ptr1, maybePtr1) { } else { return false; }
	if_def (ptr2, maybePtr2) { } else { return false; }
	assertIsValue(ptr1);
	assertIsValue(ptr2);
	def value1 = *(struct Value **)ptr1;
	def value2 = *(struct Value **)ptr2;
	if (value1->typeDesc != value2->typeDesc) return false;
	assert(value1->typeDesc->name == value2->typeDesc->name);
	return value1->typeDesc->equalFunc(ptr1, ptr2);
}


const char * getName_Value( void *_nil maybePtr )
{
	if_def (ptr, maybePtr) { } else { return ""; }
	assertIsValue(ptr);
	def value = *(struct Value **)ptr;
	return value->typeDesc->name;
}


Hash_Value hash_Value( void * ptr, bool hashIsDeep )
{
	assertIsValue(ptr);
	def value = *(struct Value **)ptr;
	return value->typeDesc->hashFunc(ptr, hashIsDeep);
}


const char * createDescription_Value( void *_nil maybePtr )
{
	if_def (ptr, maybePtr) { } else { return strdup("<nil>"); }
	assertIsValue(ptr);
	def value = *(struct Value **)ptr;
	return value->typeDesc->createDescFunc(ptr);
}


const void *_nil freeze_Value( void *_nil maybePtr )
{
	if_def (ptr, maybePtr) { } else { return nil; }
	assertIsValue(ptr);
	def value = *(struct Value **)ptr;

	if (value->immutableFlag) {
		assert(value->frozenFlag);
		return maybePtr;
	}

	if (!value->frozenFlag) {
		value->frozenFlag = true;
		if_def (freezeFunc, value->typeDesc->freezeFunc) {
			freezeFunc(ptr);
		}
	}
	return maybePtr;
}


void * create_Value(
	bool mutable,
	uint16_t size,
	const struct ValueTypeDescriptor * const typeDesc )
{
	assert(size >= sizeof(struct Value *));
	def valueAlignment = alignof(struct Value);
	def alignedSize =
		(size + valueAlignment - 1) & ~(valueAlignment - 1);
	def totalSize = alignedSize + sizeof(struct Value);

	def result = calloc(1, totalSize);

	def value = (struct Value *)((uint8_t *)result + alignedSize);
    *(struct Value **)result = value;

	value->typeDesc = typeDesc;
	value->refCount = 1;
	value->size = alignedSize;

	value->frozenFlag = !mutable;
	value->immutableFlag = !mutable;

#if CHECKS_ARE_ENABLED
	value->checksum = calcChecksum(value);
#endif

	return result;
}

// ============================================================================
end_impl