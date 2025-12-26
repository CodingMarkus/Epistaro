#include "value.h"

#include "type.h"
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


struct ValueHeader {
	// First byte
	struct TypeHeader typeHdr;
	// Second byte
	int8e threadSafeFlag:1;
	int8e frozenFlag:1;
	int8e immutableFlag:1;
	int8e reserved:5;
	// Third and fourth byte
	int16e size:16;

	union {
		int32m refCount;
		_Atomic(int32m) atomicRefCount;
	};
};


struct ValueFooter {
	const struct ValueTypeDescriptor * typeDesc;
#if ANY_CHECKS_ENABLED
	int32e checksum;
#endif
#if HEAVY_CHECKS_ENABLED
	Hash_Hasher hash;
#endif
};

// ----------------------------------------------------------------------------

static inline
const struct ValueFooter * getFooter( const struct ValueHeader * header )
{
	def alignment = alignof(struct ValueHeader);
	def size = (size_t)header->size;
	def alignedSize = (size + alignment - 1) & ~(alignment - 1);
	return (struct ValueFooter *)((const int8e *)header + alignedSize);
}


#if ANY_CHECKS_ENABLED

static inline
int32e calcChecksum(
	const struct ValueHeader * header,
	const struct ValueFooter * footer )
{
#define f32feed(state, value) ({ \
    def _tmp = (value); \
    def _size = sizeof(_tmp); \
    Fletcher32Update((state), &_tmp, _size); \
})
	struct Fletcher32State st = { 0 };

	def size = (int16e)header->size;
    st = f32feed(st, size);

    st = f32feed(st, (const void *)footer->typeDesc);
#if HEAVY_CHECKS_ENABLED
	st = f32feed(st, (const void *)footer->typeDesc->name);
	st = f32feed(st, (const void *)footer->typeDesc->copyFunc);
	st = f32feed(st, (const void *)footer->typeDesc->destroyFunc);
	st = f32feed(st, (const void *)footer->typeDesc->createDescFunc);
#endif // HEAVY_CHECKS_ENABLED

#undef f32feed
    return Fletcher32Finalize(st);
}

#endif // ANY_CHECKS_ENABLED


static inline
const struct ValueFooter * assertIsValueAndGetFooter( const void * ptr )
{
	def header = (struct ValueHeader *)ptr;
	def footer = getFooter(header);

#if ANY_CHECKS_ENABLED
	def type = (enum BaseType)header->typeHdr.type;
	assert(type == BaseType_Value_NativeCStruct);

	assert(calcChecksum(header, footer) == footer->checksum);

	if (likely_true(!header->threadSafeFlag)) {
		assert(header->refCount > 0);
	} else {
		def count = atomic_load(&header->atomicRefCount);
		assert(count > 0);
	}
#endif

	return footer;
}


static inline
struct ValueHeader * incRefCount( struct ValueHeader * header )
{
	if (likely_true(!header->threadSafeFlag)) {
		assert(header->refCount > 0);
		assert(header->refCount < UINT32_MAX);
		header->refCount++;
		return header;
	}
	def oldCount = atomic_fetch_add(&header->atomicRefCount, 1);
	assert(oldCount > 0);
	assert(oldCount < UINT32_MAX);
	return header;
}


static inline
bool decRefCount( struct ValueHeader * header )
{
	if (likely_true(!header->threadSafeFlag)) {
		assert(header->refCount > 0);
		return (--header->refCount != 0);
	}
	uint_fast32_t oldCount = atomic_fetch_sub(&header->atomicRefCount, 1);
	assert(oldCount > 0);
	return (oldCount != 1);
}


static inline
void decRefCountAndFree(
	struct ValueHeader * header, const struct ValueFooter * footer )
{
	if (likely_false(!decRefCount(header))) {
		guard (destroyFunc, footer->typeDesc->destroyFunc) {
			destroyFunc(header);
		} endguard;
		free(header);
	}
}

// // ----------------------------------------------------------------------------

public
Opt(void *) retain_Value( Opt(void *) maybePtr )
{
	guard (ptr, maybePtr) {
		assertIsValueAndGetFooter(ptr);
		def header = (struct ValueHeader *)ptr;
		incRefCount(header);
	} endguard;
	return maybePtr;
}


public
void discard_Value( Opt(void *) maybePtr )
{
	guard (ptr, maybePtr) {
		def footer = assertIsValueAndGetFooter(ptr);
		def header = (struct ValueHeader *)ptr;
		decRefCountAndFree(header, footer);
	} endguard;
}


public
Opt(const char *) getName_Value( Opt(void *) maybePtr )
{
	guard (ptr, maybePtr) {
		assertIsValueAndGetFooter(ptr);
		def footer = assertIsValueAndGetFooter(ptr);
		return footer->typeDesc->name;
	} endguard;
	return nil;
}


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


bool isEqual_Value( Opt(const void *) maybePtr1, Opt(const void *) maybePtr2 )
{
	return_unless (false, ptr1, maybePtr1);
	return_unless (false, ptr2, maybePtr2);
	def footer1 = assertIsValueAndGetFooter(ptr1);
	def footer2 = assertIsValueAndGetFooter(ptr2);
	if (footer1->typeDesc != footer2->typeDesc) return false;
#if ANY_CHECKS_ENABLED
	assert(footer1->typeDesc->name == footer2->typeDesc->name);
	assert(
		0 == strcmp(
			footer1->typeDesc->name,
			footer2->typeDesc->name
		)
	);
#endif
	return footer1->typeDesc->equalFunc(ptr1, ptr2);
}


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

public
void * create_Value(
	bool mutable,
	uint16_t size,
	const struct ValueTypeDescriptor * const typeDesc )
{
	assert(size >= sizeof(struct Value *));
	def valueAlignment = alignof(struct ValueHeader);
	def alignedSize =
		(size + valueAlignment - 1) & ~(valueAlignment - 1);
	def totalSize = alignedSize
		+ sizeof(struct ValueHeader)
		+ sizeof(struct ValueFooter);

	def result = calloc(1, totalSize);
	def header = (struct ValueHeader *)result;

	header->typeHdr.type = BaseType_Value_NativeCStruct;
	header->refCount = 1;
	header->size = alignedSize;
	header->frozenFlag = !mutable;
	header->immutableFlag = !mutable;

	def footer = (struct ValueFooter *)getFooter(result);
	footer->typeDesc = typeDesc;

#if LIGHT_CHECKS_ENABLED
	footer->checksum = calcChecksum(header, footer);
#endif

	return result;
}

// ============================================================================
end_impl
