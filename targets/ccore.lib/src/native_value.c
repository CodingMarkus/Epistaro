#include "native_value.h"

#include "base/type.h"
#include "base/fletcher32.h"

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
#if ANY_CHECKS_ENABLED
	int32e checksum;
#endif
#if HEAVY_CHECKS_ENABLED
	HashValue_Hasher hash;
#endif
	const struct TypeDescriptor_NativeValue * typeDesc;
};

// ----------------------------------------------------------------------------

#if ANY_CHECKS_ENABLED

static
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
const struct ValueFooter * getFooter( const struct ValueHeader * header )
{
	def alignment = alignof(struct ValueHeader);
	def size = (intS)header->size;
	def alignedSize = (size + alignment - 1) & ~(alignment - 1);
	return (struct ValueFooter *)((const int8e *)header + alignedSize);
}


static inline
Opt(const struct ValueFooter *) assertIsValue( const NativeValue * value )
{
#if ANY_CHECKS_ENABLED
	def header = (struct ValueHeader *)value;
	def type = (enum BaseType)header->typeHdr.type;
	assert(type == BaseType_Value_Native);

	def footer = getFooter(header);
	assert(calcChecksum(header, footer) == footer->checksum);

	if (likely_true(!header->threadSafeFlag)) {
		assert(header->refCount > 0);
	} else {
		def count = atomic_load(&header->atomicRefCount);
		assert(count > 0);
	}
	return footer;
#else
	return nil;
#endif
}


static inline
const struct ValueFooter * assertIsValueAndGetFooter(
	const NativeValue * value )
{
	return assertIsValue(value) ?: getFooter((struct ValueHeader *)value);
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
			destroyFunc((NativeValue *)header);
		} endguard;
		free(header);
	}
}

// // ----------------------------------------------------------------------------

public
NativeValue * retain_NativeValue( NativeValue * value )
{
	assertIsValue(value);
	def header = (struct ValueHeader *)value;
	incRefCount(header);
	return value;
}


public
void discard_NativeValue( Opt(NativeValue *) optValue )
{
	return_unless(no_value, value, optValue);
	def footer = assertIsValueAndGetFooter(value);
	def header = (struct ValueHeader *)value;
	decRefCountAndFree(header, footer);
}


public
const char * getName_NativeValue( Opt(NativeValue *) optValue )
{
	return_unless(strdup("<nil>"), value, optValue);
	def footer = assertIsValueAndGetFooter(value);
	return footer->typeDesc->name;
}


public
const char * createDescription_NativeValue( Opt(NativeValue *) optValue )
{
	return_unless(strdup("<nil>"), value, optValue);
	def footer = assertIsValueAndGetFooter(value);
	return footer->typeDesc->createDescFunc(value);
}


public
HashValue_Hasher hash_NativeValue( Opt(const NativeValue *) optValue )
{
	return_unless(0, value, optValue);
	assertIsValue(value);
	int8e hasherStorage[getRequiredSize_Hasher()];
	def hasher = init_Hasher(hasherStorage);
	hashWithHasher_NativeValue(value, hasher);
	return finalize_Hasher(hasher);
}


public
void hashWithHasher_NativeValue(
	Opt(const NativeValue *) optValue, Hasher * hasher )
{
	return_unless(no_value, value, optValue);
	def footer = assertIsValueAndGetFooter(value);
	footer->typeDesc->hashFunc(value, hasher);
}


public
NativeValue * copy_NativeValue( NativeValue * value, bool copyIsDeep )
{
	def footer = assertIsValueAndGetFooter(value);
	def header = (struct ValueHeader *)value;

	if (header->immutableFlag) {
		incRefCount(header);
		return value;
	}

	return footer->typeDesc->copyFunc(value, copyIsDeep);
}


public
bool isEqual_NativeValue(
	Opt(const NativeValue *) optValue,
	Opt(const NativeValue *) optOtherValue )
{
	return_unless(false, value1, optValue);
	return_unless(false, value2, optOtherValue);
	def footer1 = assertIsValueAndGetFooter(value1);
	def footer2 = assertIsValueAndGetFooter(value2);
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

	return footer1->typeDesc->equalFunc(value1, value2);
}


public
NativeValue * freeze_NativeValue( NativeValue * value )
{
	assertIsValue(value);
	def header = (struct ValueHeader *)value;

	// Requires no freezing?
	if (header->immutableFlag) {
		assert(header->frozenFlag);
#if HEAVY_CHECKS_ENABLED
		def footer = (struct ValueFooter *)getFooter(header);
		footer->hash = hash_NativeValue(value);
#endif
		return value;
	}

	// Is already frozen?
	if (header->frozenFlag) {
#if HEAVY_CHECKS_ENABLED
		def footer = (struct ValueFooter *)getFooter(header);
		def currentHash = hash_NativeValue(value);
		assert(
			currentHash == footer->hash,
			"Frozen value was modified after freezing."
		);
#endif
		return value;
	}

	// Freeze it!
	def footer = (struct ValueFooter *)getFooter(header);
	header->frozenFlag = true;
	guard (freezeFunc, footer->typeDesc->freezeFunc) {
		freezeFunc(value);
	} endguard;
#if HEAVY_CHECKS_ENABLED
	footer->hash = hash_NativeValue(value);
#endif

	return value;
}


public
NativeValue * unfreeze_NativeValue( NativeValue * value )
{
	def footer = assertIsValueAndGetFooter(value);
	def header = (struct ValueHeader *)value;

	if (!header->frozenFlag) {
		incRefCount(header);
		return value;
	}

#if HEAVY_CHECKS_ENABLED
	def currentHash = hash_NativeValue(value);
	assert(
		currentHash == footer->hash,
		"Frozen value was modified after freezing."
	);
#endif
	return footer->typeDesc->copyFunc(value, false);
}


public
bool set_NativeValue( OutPtr(NativeValue *) valuePtr, NativeValue * newValue )
{
	assertIsValue(newValue);
	def oldValue = *valuePtr;
	if (oldValue == newValue) return false;

	*valuePtr = (struct NativeValue *)incRefCount(
		(struct ValueHeader *)newValue);
	discard_NativeValue(oldValue);
	return true;
}


public
bool setOpt_NativeValue(
	OutPtrOpt(NativeValue *) valuePtr, Opt(NativeValue *) newValue )
{
	if (newValue) assertIsValue((NativeValue *)newValue);
	def oldValue = *valuePtr;
	if (oldValue == newValue) return false;

	*valuePtr = (newValue ?
		(struct NativeValue *)incRefCount((struct ValueHeader *)newValue)
		: nil
	);
	if (oldValue) discard_NativeValue(oldValue);
	return true;
}


public
bool unfreezeInPlace_NativeValue( OutPtr(NativeValue *) valuePtr )
{
	def value = *valuePtr;
	def footer = assertIsValueAndGetFooter(value);
	def header = (struct ValueHeader *)value;

	if (!header->frozenFlag) return false;

#if HEAVY_CHECKS_ENABLED
	def currentHash = hash_NativeValue(value);
	assert(
		currentHash == footer->hash,
		"Frozen value was modified after freezing."
	);
#endif

	*valuePtr = footer->typeDesc->copyFunc(value, false);
	discard_NativeValue(value);
	return true;
}


public
bool unfreezeInPlaceOpt_NativeValue( OutPtrOpt(NativeValue *) optValuePtr )
{
	if (!*optValuePtr) return false;
	def value = (NativeValue *)*optValuePtr;

	assertIsValue(value);
	def header = (struct ValueHeader *)value;
	if (!header->frozenFlag) return false;

	def footer = getFooter(header);

#if HEAVY_CHECKS_ENABLED
	def currentHash = hash_NativeValue(value);
	assert(
		currentHash == footer->hash,
		"Frozen value was modified after freezing."
	);
#endif

	*optValuePtr = footer->typeDesc->copyFunc(value, false);
	discard_NativeValue(value);
	return true;
}


// ----------------------------------------------------------------------------

public
NativeValue * create_NativeValue(
	bool mutable,
	uint16_t size,
	const struct TypeDescriptor_NativeValue * const typeDesc )
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

	header->typeHdr.type = BaseType_Value_Native;
	header->refCount = 1;
	header->size = size;
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
