#include "fletcher32.h"

#include <stdalign.h>
#include <stdatomic.h>

#include "base/begin_impl.h"
begin_impl
// ============================================================================

#if TESTING || DEBUGGING
	#define HEAVY_CHECKS_ENABLED 1
#endif
#if DEVELOPING
	#define LIGHT_CHECKS_ENABLED 1
#endif
#if LIGHT_CHECKS_ENABLED || HEAVY_CHECKS_ENABLED
	#define ANY_CHECKS_ENABLED 1
#endif


defEnum( Type, int ) {
	Type_NativeCStruct = 0
};


struct ValueHeader {
	// First byte
	int32e type:2;
	int32e threadSafeFlag:1;
	int32e frozenFlag:1;
	int32e immutableFlag:1;
	int32e reserved:3;
	// Second byte
	int32e reserved2:8;
	// Third and fourth byte
	int32e size:16;

	union {
		int32m refCount;
		_Atomic(int32m) atomicRefCount;
	};
};


struct AnyValue {
	ValueStruct
};
static_assert(
	sizeof(struct AnyValue) == sizeof(struct ValueHeader),
	"ValueStruct has incorrect size"
);


struct ValueFooter {
	const struct ValueTypeDescriptor * typeDesc;
#if ANY_CHECKS_ENABLED
	int32e checksum;
#endif
#if HEAVY_CHECKS_ENABLED
	Hash_Value hash;
#endif
};

// ----------------------------------------------------------------------------

static inline
const struct ValueFooter * getFooter( const struct AnyValue * value )
{

}


#if ANY_CHECKS_ENABLED

static inline
int32e calcChecksum( const struct AnyValue * value )
{
#define f32feed(state, value) ({ \
    def _tmp = (value); \
    def _size = sizeof(_tmp); \
    Fletcher32Update((state), &_tmp, _size); \
})
	struct Fletcher32State st = { 0 };

	def header = (const struct ValueHeader *)value;
	def size = (int16e)header->size;
    st = f32feed(st, size);

	def footer = getFooter(value);
    st = f32feed(st, (const void *)footer->typeDesc);
#if HEAVY_CHECKS_ENABLED
	st = f32feed(st, (const void *)footer->typeDesc->name);
	st = f32feed(st, (const void *)footer->typeDesc->copyFunc);
	st = f32feed(st, (const void *)footer->typeDesc->destroyFunc);
	st = f32feed(st, (const void *)footer->typeDesc->createDescFunc);
#endif

#undef f32feed
    return Fletcher32Finalize(st);
}

#endif

// static inline
// void assertIsValue( void * ptr )
// {
// 	def value = *(struct Value **)ptr;
// 	assert(
// 		calcChecksum(value) == value->checksum
// 	);
// 	if (likely_true(!value->threadSafeFlag)) {
// 		assert(value->refCount > 0);
// 	} else {
// 		def count = atomic_load(&value->atomicRefCount);
// 		assert(count > 0);
// 	}
// }

// #else
// 	#define assertIsValue(...)
// #endif


// static inline
// struct Value * incRefCount( struct Value * value )
// {
// 	if (likely_true(!value->threadSafeFlag)) {
// 		assert(value->refCount > 0);
// 		assert(value->refCount < UINT32_MAX);
// 		value->refCount++;
// 		return value;
// 	}
// 	def oldCount = atomic_fetch_add(&value->atomicRefCount, 1);
// 	assert(oldCount > 0);
// 	assert(oldCount < UINT32_MAX);
// 	return value;
// }


// static inline
// bool decRefCount( struct Value * value )
// {
// 	if (likely_true(!value->threadSafeFlag)) {
// 		assert(value->refCount > 0);
// 		return (--value->refCount != 0);
// 	}
// 	uint_fast32_t oldCount = atomic_fetch_sub(&value->atomicRefCount, 1);
// 	assert(oldCount > 0);
// 	return (oldCount != 1);
// }


// static inline
// void decRefCountAndFree( struct Value * value, void * ptr )
// {
// 	if (likely_false(!decRefCount(value))) {
// 		guard (destroyFunc, value->typeDesc->destroyFunc) {
// 			destroyFunc(ptr);
// 		} endguard;
// 		free(ptr);
// 	}
// }

// // ----------------------------------------------------------------------------

// Opt(void *) retain_Value( Opt(void *) maybePtr )
// {
// 	guard (ptr, maybePtr) {
// 		assertIsValue(ptr);
// 		def value = *(struct Value **)ptr;
// 		incRefCount(value);
// 	} endguard;
// 	return maybePtr;
// }


// void discard_Value( Opt(void *) maybePtr )
// {
// 	guard (ptr, maybePtr) {
// 		assertIsValue(ptr);
// 		def value = *(struct Value **)ptr;
// 		decRefCountAndFree(value, ptr);
// 	} endguard;
// }


// Opt(void *) copy_Value( Opt(void *) maybePtr, enum CopyStyle_Value style )
// {
// 	return_unless (nil, ptr, maybePtr);
// 	assertIsValue(ptr);
// 	def value = *(struct Value **)ptr;

// 	if (value->immutableFlag) {
// 		incRefCount(value);
// 		if (likely_false(style == ThreadSafe_CopyStyle_Value)) {
// 			value->threadSafeFlag = true;
// 			def copy = value->typeDesc->copyFunc(ptr, style);
// 			assert(copy == ptr);
// 			return copy;
// 		}
// 		return ptr;
// 	}

// 	assert(!value->threadSafeFlag);
// 	return value->typeDesc->copyFunc(ptr, style);
// }


// bool isEqual_Value( Opt(void *) maybePtr1, Opt(void *) maybePtr2 )
// {
// 	return_unless (false, ptr1, maybePtr1);
// 	return_unless (false, ptr2, maybePtr2);
// 	assertIsValue(ptr1);
// 	assertIsValue(ptr2);
// 	def value1 = *(struct Value **)ptr1;
// 	def value2 = *(struct Value **)ptr2;
// 	if (value1->typeDesc != value2->typeDesc) return false;
// 	assert(value1->typeDesc->name == value2->typeDesc->name);
// 	return value1->typeDesc->equalFunc(ptr1, ptr2);
// }


// const char * getName_Value( Opt(void *) maybePtr )
// {
// 	return_unless ("", ptr, maybePtr);
// 	assertIsValue(ptr);
// 	def value = *(struct Value **)ptr;
// 	return value->typeDesc->name;
// }


// Hash_Value hash_Value( void * ptr, bool hashIsDeep )
// {
// 	assertIsValue(ptr);
// 	def value = *(struct Value **)ptr;
// 	return value->typeDesc->hashFunc(ptr, hashIsDeep);
// }


// const char * createDescription_Value( Opt(void *) maybePtr )
// {
// 	return_unless ("<nil>", ptr, maybePtr);
// 	assertIsValue(ptr);
// 	def value = *(struct Value **)ptr;
// 	return value->typeDesc->createDescFunc(ptr);
// }


// Opt(const void *) freeze_Value( Opt(void *) maybePtr )
// {
// 	return_unless (nil, ptr, maybePtr);
// 	assertIsValue(ptr);
// 	def value = *(struct Value **)ptr;

// 	if (value->immutableFlag) {
// 		assert(value->frozenFlag);
// 		return maybePtr;
// 	}



// 	if (!value->frozenFlag) {
// 		value->frozenFlag = true;
// 		guard (freezeFunc, value->typeDesc->freezeFunc) {
// 			freezeFunc(ptr);
// 		} endguard;
// 	}

// 	return maybePtr;
// }


// Opt(void *) unfreeze_Value( Opt(void *) maybePtr )
// {
// 	return_unless (nil, ptr, maybePtr);
// 	assertIsValue(ptr);
// 	def value = *(struct Value **)ptr;

// 	if (value->frozenFlag) return copy_Value(ptr, Deep_CopyStyle_Value);

// 	incRefCount(value);
// 	return ptr;
// }


// void set_Value( Opt(void *) * oldValuePtr,  Opt(void *) maybePtr )
// {
// 	if (*oldValuePtr == maybePtr) return;
// 	guard (newPtr, maybePtr) {
// 		assertIsValue(newPtr);
// 		def newValue = *(struct Value **)newPtr;
// 		incRefCount(newValue);
// 	} endguard;
// 	guard (oldPtr, *oldValuePtr) {
// 		assertIsValue(oldPtr);
// 		def oldValue = *(struct Value **)oldPtr;
// 		decRefCountAndFree(oldValue, oldPtr);
// 	} endguard;
// 	*oldValuePtr = maybePtr;
// 	return;
// }

// // ----------------------------------------------------------------------------

// void * create_Value(
// 	bool mutable,
// 	uint16_t size,
// 	const struct ValueTypeDescriptor * const typeDesc )
// {
// 	assert(size >= sizeof(struct Value *));
// 	def valueAlignment = alignof(struct Value);
// 	def alignedSize =
// 		(size + valueAlignment - 1) & ~(valueAlignment - 1);
// 	def totalSize = alignedSize + sizeof(struct Value);

// 	def result = calloc(1, totalSize);

// 	def value = (struct Value *)((uint8_t *)result + alignedSize);
//     *(struct Value **)result = value;

// 	value->typeDesc = typeDesc;
// 	value->refCount = 1;
// 	value->size = alignedSize;

// 	value->frozenFlag = !mutable;
// 	value->immutableFlag = !mutable;

// #if CHECKS_ARE_ENABLED
// 	value->checksum = calcChecksum(value);
// #endif

// 	return result;
// }

// ============================================================================
end_impl