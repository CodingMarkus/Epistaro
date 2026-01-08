#pragma once

#include "hasher.h"

#include "base/begin_header.h"
begin_header
// ============================================================================

typedef struct NativeValue  NativeValue;


/**
	Compute a hash that reflects the value's state.

	The hash must change when any state that affects `EqualFunc_NativeValue`
	changes. Equal values must yield identical hashes. Collisions remain
	possible.
*/
typedef void (HashFunc_NativeValue)(
	const NativeValue * value,
	Hasher * hasher, const HasherInterface hasherIntf
);


/**
	Compare two values and return `true` only if they are fully functionally
	equivalent. All observable behavior and referenced state must match
	exactly. Both values are never `nil` and `otherValue` is guaranteed to
	be of the same type as `value`.
*/
typedef bool (EqualFunc_NativeValue)(
	const NativeValue * value, const NativeValue * otherValue
);


/**
	Called when a value gets frozen to ensure that internal state is frozen
	if required.
*/
typedef void (FreezeFunc_NativeValue)( Opt(NativeValue *) value );


/**
	Create a copy of the value.

	If `copyIsDeep` is `true`, nested or referenced data will also be
	recursively copied, producing a fully independent clone; otherwise only
	a shallow copy should be made.
 */
typedef void * (CopyFunc_NativeValue)(
	const NativeValue * value, bool copyIsDeep
);


/**
	Perform optional additional clean-up when an object is about to be
	destroyed, e.g. releasing resources that are not value references.
*/
typedef void (DestroyFunc_NativeValue)( const NativeValue * value );


/**
	Create a human-readable description string of the value.
	The caller must free the returned string.
*/
typedef char * (CreateDescFunc_NativeValue)( const NativeValue * value );


/**
	@param name Printable type name. For a given type, the pointer identity
		must be stable across instances (`==` must hold).
	@param hashFunc Function to compute a value's hash. See
		`HashFunc_NativeValue`.
	@param copyFunc Function to copy the value. See `CopyFunc_NativeValue`.
	@param equalFunc Function to compare objects. See `EqualFunc_NativeValue`.
	@param freezeFunc Function to freeze referenced values. Set to `nil` if
		the value has no references or only points to frozen values. See
		`FreezeFunc_NativeValue`.
	@param destroyFunc Function for extra clean-up before destruction. Set to
		`nil` if no clean-up is needed beyond freeing memory. See
		`DestroyFunc_NativeValue`.
	@param createDescFunc Function that creates a human-readable description.
		Useful for logging and debugging. Caller frees the returned string.
		See `CreateDescFunc_NativeValue`.

	@note
	Two values are the same type only when their type descriptors match
	(`==` must be true) and their `name` pointers also match.
*/
struct TypeDescriptor_NativeValue {
	const char * name;
	HashFunc_NativeValue * hashFunc;
	CopyFunc_NativeValue * copyFunc;
	EqualFunc_NativeValue * equalFunc;
	CreateDescFunc_NativeValue * createDescFunc;
	Opt(FreezeFunc_NativeValue *) freezeFunc;
	Opt(DestroyFunc_NativeValue *) destroyFunc;
};

// // ----------------------------------------------------------------------------

/**
	Increment the object's reference count and return the same pointer.
*/
NativeValue * retain_NativeValue( NativeValue * optValue );


/**
	Balance a previous creation or retain. Destroys the value when the
	reference count reaches zero.
*/
void discard_NativeValue( Opt(NativeValue *) optValue );


/**
	Get name of the value type as a printable string.
*/
const char * getName_NativeValue( Opt(NativeValue *) optValue );


/**
	Create a human readable description of the value.
	Caller must free description using `free()`.
*/
const char * createDescription_NativeValue( Opt(NativeValue *) value );


/**
	Returns a hash value that represents the value's current state.
	Two objects that are equal according to `EqualFunc_NativeValue` must
	produce the same hash value. Different objects may still collide.

	Generates a suitable `Hasher` on the stack and passes it to
	`HashFunc_NativeValue`.
*/
HashValue_Hasher hash_NativeValue( Opt(const NativeValue *) value );


/**
	Update `hasher` with the value's current state.
	Two objects that are equal according to `EqualFunc_NativeValue` must
	produce the same hash stream. Different objects may still collide.
*/
void hashWithHasher_NativeValue(
	Opt(const NativeValue *) value,
	Hasher * hasher, const HasherInterface * hashIntf
);


/**
	Either returns the same value with an increased retain count (if
	immutable), or returns a new copy (deep or shallow depending on flag).
 */
NativeValue * copy_NativeValue( NativeValue * value, bool copyIsDeep );


/**
	Test two values for equality.

	@returns `true` only if they are fully functionally equivalent. All
	observable behavior and referenced state must match exactly. Always
	`false` if either value is `nil`!
*/
bool isEqual_NativeValue(
	Opt(const NativeValue *) value,
	Opt(const NativeValue *) otherValue
);


/**
	Mark the value for copy-on-write on the next modification because an
	immutable reference to that value is required. Does nothing if the value
	is immutable, as immutable values are always frozen.
*/
NativeValue * freeze_NativeValue( NativeValue * value );



/**
	If the value is not frozen, just retains the value and returns it.
	If the value is frozen, creates a copy and returns it.
*/
NativeValue * unfreeze_NativeValue( NativeValue * value );


/**
	Discards the current value `valuePtr` points to, retains `newValue` and
	assigns it to `valuePtr`. It does in a safe manner, so nothing goes wrong,
	even if `valuePtr` already points to `newValue`.

	@code
	// Equivalent code but set_NativeValue() is more efficient
	def oldValue = *valuePtr;
	*valuePtr = retain_NativeValue(newValue);
	discard_NativeValue(oldValue);
	@endcode

	@returns Whether `valuePtr` was actually mutated or not.
*/
bool set_NativeValue( OutPtr(NativeValue *) valuePtr, NativeValue * newValue );


/**
	Works exactly like `set_NativeValue()` but `valuePtr` may point to `nil`
	and the value being set may be `nil` as well.

	@see set_NativeValue()
*/
bool setOpt_NativeValue(
	OutPtrOpt(NativeValue *) valuePtr, Opt(NativeValue *) newValue
);


/**
	If the value is frozen, unfreezes in place, discards the old frozen
	value, and replaces it with the unfrozen copy. Does nothing if the value
	is not frozen.

	@code
	// Equivalent code but unfreezeInPlace_NativeValue() is more efficient
	def oldValue = *valuePtr;
	*valuePtr = unfreeze_NativeValue(oldValue);
	discard_NativeValue(oldValue);
	@endcode

	@returns Whether `valuePtr` was actually mutated or not.
*/
bool unfreezeInPlace_NativeValue( OutPtr(NativeValue *) valuePtr );


/**
	Works exactly like `unfreezeInPlace_NativeValue()` but `valuePtr` may point
	to `nil`, in which case there is nothing to unfreeze.

	@see unfreezeInPlace_NativeValue()
*/
bool unfreezeInPlaceOpt_NativeValue( OutPtrOpt(NativeValue *) valuePtr );



// ----------------------------------------------------------------------------

/**
	@param size Total size of the encapsulated struct in bytes, including
		any struct padding.
	@param typeDesc Pointer to the value's type descriptor.

	@returns Pointer to the newly allocated value.

	@code
	typedef NativeValue StringStorage;

	struct StringStorage {
		// StringStorage-specific fields
	};

	StringStorage * str = create_NativeValue(
		true, sizeof(struct StringStorage), &StringStorageType
	);
	@endcode

	@note
	All fields are zero-initialized (0, false, nil, etc.).

	@warning
	If the structure ends with a flexible array member
	(e.g. `int8e data[];` or `int8e data[0];`), include the
	runtime size of that array in `size`.
*/
NativeValue * create_NativeValue(
	bool immutable,
	uint16_t size,
	const struct TypeDescriptor_NativeValue * const typeDesc
);

// ============================================================================
end_header
#include "base/end_header.h"
