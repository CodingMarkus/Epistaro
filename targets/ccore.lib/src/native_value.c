#include "native_value.h"

#include "base/type.h"
#include "base/fletcher32.h"
#include "base/hashes/xxh3.h"
#include "base/hashes/xxh32.h"
#include "base/common/optional/begin_targets.h"
#include "base/common/optional/end_targets.h"

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
	def alignment = alignof(struct ValueFooter);
	def size = (intS)header->size;
	def footerOffset =
		(sizeof(struct ValueHeader) + size + alignment - 1)
		& ~(alignment - 1);
	return (struct ValueFooter *)((const int8e *)header + footerOffset);
}


static inline
Opt(const struct ValueFooter *) requireToBeValue( const NativeValue * value )
{
	def header = (struct ValueHeader *)value;
	def type = (enum BaseType)header->typeHdr.type;
	require(type == BaseType_Value_Native);

#if ANY_CHECKS_ENABLED
	def footer = getFooter(header);
	require(calcChecksum(header, footer) == footer->checksum);

	if (likely_true(!header->threadSafeFlag)) {
		require(header->refCount > 0);
	} else {
		def count = atomic_load(&header->atomicRefCount);
		require(count > 0);
	}
	return footer;
#else
	return nil;
#endif
}


static inline
const struct ValueFooter * requireToBeValueAndGetFooter(
	const NativeValue * value )
{
	return requireToBeValue(value) ?: getFooter((struct ValueHeader *)value);
}


static inline
void * getPayloadPtr( struct ValueHeader * header )
{
	return (void *)((int8e *)header + sizeof(struct ValueHeader));
}


static inline
const void * getPayloadPtrConst( const struct ValueHeader * header )
{
	return (const void *)((const int8e *)header + sizeof(struct ValueHeader));
}

static inline
struct ValueHeader * incRefCount( struct ValueHeader * header )
{
	if (likely_true(!header->threadSafeFlag)) {
		require(header->refCount > 0);
		require(header->refCount < UINT32_MAX);
		header->refCount++;
		return header;
	}
	def oldCount = atomic_fetch_add(&header->atomicRefCount, 1);
	require(oldCount > 0);
	require(oldCount < UINT32_MAX);
	return header;
}


static inline
bool decRefCount( struct ValueHeader * header )
{
	if (likely_true(!header->threadSafeFlag)) {
		require(header->refCount > 0);
		return (--header->refCount != 0);
	}
	uint_fast32_t oldCount = atomic_fetch_sub(&header->atomicRefCount, 1);
	require(oldCount > 0);
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


static inline
void discardValue( Opt(NativeValue *) optValue )
{
	return_unless(no_value, value, optValue);
	def footer = requireToBeValueAndGetFooter(value);
	def header = (struct ValueHeader *)value;
	decRefCountAndFree(header, footer);
}


static inline
bool unfreezeInPlace( NativeValue ** valuePtr, bool allowNil )
{
	def value = *valuePtr;
	if (allowNil && !value) return false;

	def footer = requireToBeValueAndGetFooter(value);
	def header = (struct ValueHeader *)value;

	if (header->immutableFlag || !header->frozenFlag) return false;

#if HEAVY_CHECKS_ENABLED
	def currentHash = hash_NativeValue(value);
	assert(
		currentHash == footer->hash,
		"Frozen value was modified after freezing."
	);
#endif

	*valuePtr = footer->typeDesc->copyFunc(value, false);
	decRefCountAndFree(header, footer);
	return true;
}


static inline
bool withMutableStorage(
	NativeValue ** valuePtr,
	bool allowNil,
	WithMutableStorageFunc_NativeValue * func,
	void * context )
{
	init value = *valuePtr;
	if (allowNil && !value) return false;

	requireToBeValue(value);
	init header = (struct ValueHeader *)value;
	require(!header->immutableFlag,
		"Cannot access mutable storage on immutable value.");

	if (header->frozenFlag) {
		unfreezeInPlace(valuePtr, allowNil);
		value = *valuePtr;
		if (allowNil && !value) return false;
		requireToBeValue(value);
		header = (struct ValueHeader *)value;
		require(!header->frozenFlag,
			"Failed to unfreeze value for mutable storage access.");
	}

	return func(
		getPayloadPtr(header),
		(intS)header->size,
		context
	);
}

// // ----------------------------------------------------------------------------

public
NativeValue * retain_NativeValue( NativeValue * value )
{
	requireToBeValue(value);
	def header = (struct ValueHeader *)value;
	incRefCount(header);
	return value;
}


public
void discard_NativeValue( Opt(NativeValue *) optValue )
{
	discardValue(optValue);
}


public
const char * getName_NativeValue( Opt(NativeValue *) optValue )
{
	return_unless(strdup("<nil>"), value, optValue);
	def footer = requireToBeValueAndGetFooter(value);
	return footer->typeDesc->name;
}


public
const char * createDescription_NativeValue( Opt(NativeValue *) optValue )
{
	return_unless(strdup("<nil>"), value, optValue);
	def footer = requireToBeValueAndGetFooter(value);
	return footer->typeDesc->createDescFunc(value);
}


public
bool withStorage_NativeValue(
	Opt(const NativeValue *) optValue,
	WithStorageFunc_NativeValue * func,
	void * context )
{
	return_unless(false, value, optValue);
	requireToBeValue(value);
	def header = (const struct ValueHeader *)value;
	return func(
		getPayloadPtrConst(header),
		(intS)header->size,
		context
	);
}


public
bool withMutableStorage_NativeValue(
	OutPtr(NativeValue *) valuePtr,
	WithMutableStorageFunc_NativeValue * func,
	void * context )
{
	return withMutableStorage(valuePtr, false, func, context);
}


public
bool withMutableStorageOpt_NativeValue(
	OutPtrOpt(NativeValue *) valuePtr,
	WithMutableStorageFunc_NativeValue * func,
	void * context )
{
	return withMutableStorage(valuePtr, true, func, context);
}


public
HashValue_Hasher hash_NativeValue( Opt(const NativeValue *) optValue )
{
	return_unless(0, value, optValue);
	requireToBeValue(value);
	const HasherInterface * hashIntf;
#if CPU_IS_64_BIT
	hashIntf = geHasherInterface_XXH3();
#else
	hashIntf = getHasherInterface_XXH32();
#endif

	int8e hasherStorage[hashIntf->getRequiredSize()];
	def hasher = hashIntf->initStorage(hasherStorage);
	hashWithHasher_NativeValue(value, hasher, hashIntf);
	return hashIntf->finalize(hasher);
}


public
void hashWithHasher_NativeValue(
	Opt(const NativeValue *) optValue,
	Hasher * hasher,
	const HasherInterface * hashIntf )
{
	return_unless(no_value, value, optValue);
	assert(hashIntf);
	def footer = requireToBeValueAndGetFooter(value);
	footer->typeDesc->hashFunc(value, hasher, *hashIntf);
}


public
NativeValue * copy_NativeValue( NativeValue * value, bool copyIsDeep )
{
	def footer = requireToBeValueAndGetFooter(value);
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
	def footer1 = requireToBeValueAndGetFooter(value1);
	def footer2 = requireToBeValueAndGetFooter(value2);
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
	requireToBeValue(value);
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
	def footer = requireToBeValueAndGetFooter(value);
	def header = (struct ValueHeader *)value;

	if (header->immutableFlag || !header->frozenFlag) {
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
	requireToBeValue(newValue);
	def oldValue = *valuePtr;
	if (oldValue == newValue) return false;

	*valuePtr = (struct NativeValue *)incRefCount(
		(struct ValueHeader *)newValue);
	discardValue(oldValue);
	return true;
}


public
bool setOpt_NativeValue(
	OutPtrOpt(NativeValue *) valuePtr, Opt(NativeValue *) newValue )
{
	if (newValue) requireToBeValue((NativeValue *)newValue);
	def oldValue = *valuePtr;
	if (oldValue == newValue) return false;

	*valuePtr = (newValue ?
		(struct NativeValue *)incRefCount((struct ValueHeader *)newValue)
		: nil
	);
	if (oldValue) discardValue(oldValue);
	return true;
}


public
bool unfreezeInPlace_NativeValue( OutPtr(NativeValue *) valuePtr )
{
	return unfreezeInPlace(valuePtr, false);
}


public
bool unfreezeInPlaceOpt_NativeValue( OutPtrOpt(NativeValue *) optValuePtr )
{
	return unfreezeInPlace(optValuePtr, true);
}


// ----------------------------------------------------------------------------

public
NativeValue * create_NativeValue(
	bool immutable,
	uint16_t size,
	const struct TypeDescriptor_NativeValue * const typeDesc )
{
	def footerAlignment = alignof(struct ValueFooter);
	def footerOffset =
		(sizeof(struct ValueHeader) + size + footerAlignment - 1)
		& ~(footerAlignment - 1);
	def totalSize = footerOffset + sizeof(struct ValueFooter);

	def result = calloc(1, totalSize);
	def header = (struct ValueHeader *)result;

	header->typeHdr.type = BaseType_Value_Native;
	header->refCount = 1;
	header->size = size;
	header->frozenFlag = immutable;
	header->immutableFlag = immutable;

	def footer = (struct ValueFooter *)getFooter(result);
	footer->typeDesc = typeDesc;

#if ANY_CHECKS_ENABLED
	footer->checksum = calcChecksum(header, footer);
#endif

	return result;
}

// ============================================================================
end_impl
